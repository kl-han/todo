import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:quadrant_usage/quadrant_usage.dart';

/// i3/Sway IPC message types (subset).
class SwayIpc {
  static const int getTree = 4;
  static const int subscribe = 2;
  static const int eventWindow = 0x80000003;
  static const int eventShutdown = 0x80000006;

  static final List<int> magic = ascii.encode('i3-ipc');

  /// Encodes one IPC frame: `i3-ipc` + u32 length + u32 type + payload,
  /// little-endian.
  static Uint8List encode(int type, String payload) {
    final body = utf8.encode(payload);
    final buffer = BytesBuilder()
      ..add(magic)
      ..add((ByteData(8)
            ..setUint32(0, body.length, Endian.little)
            ..setUint32(4, type, Endian.little))
          .buffer
          .asUint8List())
      ..add(body);
    return buffer.toBytes();
  }
}

/// One decoded IPC frame. The payload is whatever JSON the peer sent —
/// an object for events and replies, an array for SUBSCRIBE, null for
/// empty request payloads.
typedef SwayFrame = ({int type, Object? payload});

/// Incremental decoder for the i3-ipc wire format.
class SwayFrameDecoder {
  final BytesBuilder _buffer = BytesBuilder();

  List<SwayFrame> add(List<int> chunk) {
    _buffer.add(chunk);
    final frames = <SwayFrame>[];
    var bytes = _buffer.toBytes();
    while (bytes.length >= 14) {
      final length =
          ByteData.sublistView(bytes, 6, 14).getUint32(0, Endian.little);
      final type =
          ByteData.sublistView(bytes, 6, 14).getUint32(4, Endian.little);
      if (bytes.length < 14 + length) break;
      final payload = utf8.decode(bytes.sublist(14, 14 + length));
      frames.add((
        type: type,
        payload: payload.isEmpty ? null : jsonDecode(payload),
      ));
      bytes = bytes.sublist(14 + length);
    }
    _buffer
      ..clear()
      ..add(bytes);
    return frames;
  }
}

/// Sway usage collector: subscribes to `window` and `shutdown` IPC
/// events over `$SWAYSOCK` and translates focus changes into
/// [UsageEvent]s — no process scanning, no polling, no global Wayland
/// observation. Records `app_id` (or X11 class) only; titles are read
/// but forwarded solely when the recorder's policy opts in.
class SwayCollector {
  SwayCollector({
    required this.socketPath,
    required this.onEvent,
    Stopwatch? monotonic,
    DateTime Function()? clock,
  })  : _monotonic = monotonic ?? (Stopwatch()..start()),
        _clock = clock ?? (() => DateTime.now().toUtc());

  final String socketPath;
  final void Function(UsageEvent event) onEvent;
  final Stopwatch _monotonic;
  final DateTime Function() _clock;

  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;

  Future<void> start() async {
    final socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    _socket = socket;
    final decoder = SwayFrameDecoder();
    _subscription = socket.listen(
      (chunk) {
        for (final frame in decoder.add(chunk)) {
          _handleFrame(frame);
        }
      },
      onDone: _emitStopped,
      onError: (Object _) => _emitStopped(),
    );
    socket.add(SwayIpc.encode(
        SwayIpc.subscribe, jsonEncode(['window', 'shutdown'])));
    // Seed the current focus so the first interval doesn't wait for the
    // user's next window switch.
    socket.add(SwayIpc.encode(SwayIpc.getTree, ''));
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _socket?.destroy();
  }

  void _handleFrame(SwayFrame frame) {
    final payload = frame.payload;
    if (payload is! Map<String, Object?>) return; // acks, arrays, empties
    switch (frame.type) {
      case SwayIpc.eventWindow:
        if (payload['change'] == 'focus') {
          _emitFocus(payload['container'] as Map<String, Object?>?);
        }
      case SwayIpc.eventShutdown:
        _emitStopped();
      case SwayIpc.getTree:
        _emitFocus(_findFocused(payload));
      default:
        break; // unrelated replies
    }
  }

  void _emitFocus(Map<String, Object?>? container) {
    if (container == null) return;
    final appId = container['app_id'] as String? ??
        ((container['window_properties']
            as Map<String, Object?>?)?['class'] as String?);
    if (appId == null || appId.isEmpty) return;
    onEvent(FocusChanged(
      at: _clock(),
      monotonicMs: _monotonic.elapsedMilliseconds,
      applicationId: appId,
      applicationName: appId,
      windowTitle: container['name'] as String?,
    ));
  }

  void _emitStopped() {
    onEvent(CollectorStopped(
      at: _clock(),
      monotonicMs: _monotonic.elapsedMilliseconds,
    ));
  }

  /// Depth-first search for the focused leaf of a GET_TREE reply.
  static Map<String, Object?>? _findFocused(Map<String, Object?> node) {
    if (node['focused'] == true) return node;
    for (final key in ['nodes', 'floating_nodes']) {
      final children = node[key] as List<Object?>? ?? const [];
      for (final child in children) {
        final found = _findFocused(child as Map<String, Object?>);
        if (found != null) return found;
      }
    }
    return null;
  }
}
