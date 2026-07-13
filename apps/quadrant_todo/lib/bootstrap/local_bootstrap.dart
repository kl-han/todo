import 'dart:io';

import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// Local mode startup: spawn the embedded backend isolate, wait until its
/// health route answers, and hand the UI a ready connection.
///
/// The returned connection knows how to restart the backend, which the app
/// uses on resume — iOS may have frozen or killed the backend isolate along
/// with the rest of the process.
Future<BackendConnection> bootstrapLocalBackend({String? databasePath}) async {
  final path = databasePath ?? defaultLocalDatabasePath();
  final backend = await EmbeddedBackend.start(databasePath: path);
  final client = QuadrantApiClient(
    baseUrl: backend.baseUrl,
    authorization: backend.authorization,
  );
  await client.waitUntilHealthy();

  return BackendConnection(
    mode: BackendMode.local,
    client: client,
    shutdown: backend.stop,
    restart: () async {
      client.close();
      await backend.stop();
      return bootstrapLocalBackend(databasePath: path);
    },
  );
}

/// Platform-appropriate vault location for local mode.
///
/// * Linux: `$XDG_DATA_HOME/quadrant-todo/default.sqlite3`
///   (or `~/.local/share/...`).
/// * iOS/macOS: the app's Documents-adjacent HOME sandbox; v0.4 refines
///   this to the proper application-support directory.
String? defaultLocalDatabasePath() {
  final env = Platform.environment;
  final base = env['XDG_DATA_HOME'] ??
      (env['HOME'] == null ? null : '${env['HOME']}/.local/share');
  if (base == null) return null; // in-memory fallback (tests only)
  return '$base/quadrant-todo/default.sqlite3';
}
