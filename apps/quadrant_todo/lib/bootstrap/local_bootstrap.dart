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
/// * iOS: `$HOME/Library/Application Support/quadrant-todo/` inside the
///   app sandbox — backed up by the system, never user-visible, and not
///   purged like Caches.
/// * Linux: `$XDG_DATA_HOME/quadrant-todo/` (or `~/.local/share/...`).
String? defaultLocalDatabasePath() {
  final env = Platform.environment;
  if (Platform.isIOS || Platform.isMacOS) {
    final home = env['HOME'];
    if (home == null) return null;
    return '$home/Library/Application Support/quadrant-todo/'
        'default.sqlite3';
  }
  final base = env['XDG_DATA_HOME'] ??
      (env['HOME'] == null ? null : '${env['HOME']}/.local/share');
  if (base == null) return null; // in-memory fallback (tests only)
  return '$base/quadrant-todo/default.sqlite3';
}
