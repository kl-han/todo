import 'dart:convert';
import 'dart:io';

import 'package:quadrant_agent/quadrant_agent.dart';
import 'package:quadrant_usage/quadrant_usage.dart';
import 'package:test/test.dart';

void main() {
  group('SwayFrameDecoder', () {
    test('decodes frames across arbitrary chunk boundaries', () {
      final frame = SwayIpc.encode(
          SwayIpc.eventWindow,
          jsonEncode({
            'change': 'focus',
            'container': {'app_id': 'firefox', 'name': 'Home'},
          }));
      final decoder = SwayFrameDecoder();
      // Feed byte by byte: nothing until the frame completes.
      final collected = <SwayFrame>[];
      for (final byte in frame) {
        collected.addAll(decoder.add([byte]));
      }
      expect(collected, hasLength(1));
      expect(collected.single.type, SwayIpc.eventWindow);
      final payload = collected.single.payload as Map<String, Object?>;
      expect(
        (payload['container'] as Map<String, Object?>)['app_id'],
        'firefox',
      );
    });
  });

  group('SwayCollector against a fake compositor socket', () {
    late Directory dir;
    late ServerSocket server;
    late List<UsageEvent> events;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('sway-fake-');
      server = await ServerSocket.bind(
        InternetAddress('${dir.path}/sway.sock',
            type: InternetAddressType.unix),
        0,
      );
      events = [];
    });

    tearDown(() async {
      await server.close();
      dir.deleteSync(recursive: true);
    });

    test('subscribes, seeds from GET_TREE, and reports focus changes',
        () async {
      final incoming = <SwayFrame>[];
      server.listen((client) {
        final decoder = SwayFrameDecoder();
        client.listen((chunk) {
          for (final frame in decoder.add(chunk)) {
            incoming.add(frame);
            if (frame.type == SwayIpc.getTree) {
              // Reply: a tree whose focused leaf is the editor.
              client.add(SwayIpc.encode(SwayIpc.getTree, jsonEncode({
                'focused': false,
                'nodes': [
                  {
                    'focused': true,
                    'app_id': 'editor',
                    'name': 'main.dart',
                  },
                ],
              })));
              // Then a live focus change to firefox.
              client.add(SwayIpc.encode(
                  SwayIpc.eventWindow,
                  jsonEncode({
                    'change': 'focus',
                    'container': {'app_id': 'firefox', 'name': 'Home'},
                  })));
              // And a compositor shutdown.
              client.add(SwayIpc.encode(
                  SwayIpc.eventShutdown, jsonEncode({'change': 'exit'})));
            }
          }
        });
      });

      final collector = SwayCollector(
        socketPath: '${dir.path}/sway.sock',
        onEvent: events.add,
      );
      await collector.start();
      // Events arrive asynchronously over the socket.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await collector.stop();

      expect(
        events.whereType<FocusChanged>().map((e) => e.applicationId),
        ['editor', 'firefox'],
      );
      expect(events.last, isA<CollectorStopped>());
      // The collector subscribed to window and shutdown events.
      expect(incoming.first.type, SwayIpc.subscribe);
    });
  });
}
