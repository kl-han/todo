import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'local_session_token.dart';

/// The embedded local-mode backend: a dedicated isolate that binds an HTTP
/// server to `127.0.0.1` on an OS-assigned ephemeral port and serves the
/// shared REST handler.
///
/// Startup sequence (see docs/src/architecture/backend-lifecycle.rst):
/// generate a per-launch token, spawn the isolate, bind loopback port 0,
/// report the port back, then the caller polls `/api/v1/health` before
/// rendering the application.
class EmbeddedBackend {
  EmbeddedBackend._(this.port, this.token, this._isolate, this._commands);

  final int port;

  /// Per-launch session token; send as `Authorization: Local <token>`.
  final String token;

  final Isolate _isolate;
  final SendPort _commands;

  Uri get baseUrl => Uri.parse('http://127.0.0.1:$port');
  String get authorization => 'Local $token';

  static Future<EmbeddedBackend> start({String? databasePath}) async {
    final token = LocalSessionToken.generate();
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(
      _backendMain,
      _Bootstrap(ready.sendPort, token, databasePath),
      debugName: 'quadrant-embedded-backend',
      errorsAreFatal: true,
    );

    final message = await ready.first;
    ready.close();
    if (message is _Started) {
      return EmbeddedBackend._(message.port, token, isolate, message.commands);
    }
    isolate.kill(priority: Isolate.immediate);
    throw StateError('Embedded backend failed to start: $message');
  }

  /// Gracefully closes the HTTP server and ends the isolate. iOS may kill
  /// the process without ever calling this; the backend must stay correct
  /// anyway (every write commits before its HTTP response is sent).
  Future<void> stop({Duration timeout = const Duration(seconds: 2)}) async {
    final ack = ReceivePort();
    _commands.send(ack.sendPort);
    try {
      await ack.first.timeout(timeout);
    } on TimeoutException {
      _isolate.kill(priority: Isolate.immediate);
    } finally {
      ack.close();
    }
  }
}

class _Bootstrap {
  const _Bootstrap(this.ready, this.token, this.databasePath);

  final SendPort ready;
  final String token;
  // ignore: unused_field — consumed from v0.2 when the isolate owns SQLite.
  final String? databasePath;
}

class _Started {
  const _Started(this.port, this.commands);

  final int port;
  final SendPort commands;
}

Future<void> _backendMain(_Bootstrap bootstrap) async {
  final handler = buildApiHandler(
    ApiServerConfig(
      backendKind: BackendKind.embedded,
      authToken: bootstrap.token,
    ),
  );

  // Loopback only: the embedded backend must never be reachable from other
  // hosts, so binding to 0.0.0.0 is prohibited.
  final server = await shelf_io.serve(
    handler,
    InternetAddress.loopbackIPv4,
    0,
  );

  final commands = ReceivePort();
  bootstrap.ready.send(_Started(server.port, commands.sendPort));

  await for (final message in commands) {
    if (message is SendPort) {
      await server.close(force: true);
      message.send('stopped');
      break;
    }
  }
  commands.close();
}
