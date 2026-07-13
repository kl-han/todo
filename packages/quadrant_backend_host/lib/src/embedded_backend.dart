import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_store/quadrant_store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'local_session_token.dart';

/// The embedded local-mode backend: a dedicated isolate that owns the
/// SQLite database and binds an HTTP server to `127.0.0.1` on an
/// OS-assigned ephemeral port, serving the shared REST handler.
///
/// Startup sequence (see docs/src/architecture/backend-lifecycle.rst):
/// generate a per-launch token, spawn the isolate, open and migrate the
/// database, bind loopback port 0, report the port back, then the caller
/// polls `/api/v1/health` before rendering the application.
class EmbeddedBackend {
  EmbeddedBackend._(this.port, this.token, this._isolate, this._commands);

  final int port;

  /// Per-launch session token; send as `Authorization: Local <token>`.
  final String token;

  final Isolate _isolate;
  final SendPort _commands;

  Uri get baseUrl => Uri.parse('http://127.0.0.1:$port');
  String get authorization => 'Local $token';

  /// [databasePath] is the vault file; null opens an in-memory vault
  /// (tests and throwaway runs — data dies with the backend).
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

  /// Gracefully closes the HTTP server and database and ends the isolate.
  /// iOS may kill the process without ever calling this; the backend must
  /// stay correct anyway (every write commits before its HTTP response).
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
  final String? databasePath;
}

class _Started {
  const _Started(this.port, this.commands);

  final int port;
  final SendPort commands;
}

/// The fixed vault id served by the embedded backend.
const String embeddedVaultId = 'default';

Future<void> _backendMain(_Bootstrap bootstrap) async {
  // The backend isolate owns the database; the UI isolate never opens
  // SQLite directly. A corrupt local vault is moved aside and recreated —
  // the app must always boot — while the damaged file survives for triage.
  final database = bootstrap.databasePath == null
      ? QuadrantDatabase.inMemory()
      : QuadrantDatabase.openWithRecovery(bootstrap.databasePath!);
  final services = AppServices(
    taskRepository: SqliteTaskRepository(database),
    tagRepository: SqliteTagRepository(database),
  );

  final handler = buildApiHandler(
    ApiServerConfig(
      backendKind: BackendKind.embedded,
      authToken: bootstrap.token,
      schemaVersion: database.userVersion,
      vaults: (vaultId) => vaultId == embeddedVaultId ? services : null,
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
      database.close();
      message.send('stopped');
      break;
    }
  }
  commands.close();
}
