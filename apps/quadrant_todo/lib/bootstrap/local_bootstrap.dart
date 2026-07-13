import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// Local mode startup: spawn the embedded backend isolate, wait until its
/// health route answers, and hand the UI a ready connection.
///
/// The returned connection knows how to restart the backend, which the app
/// uses on resume — iOS may have frozen or killed the backend isolate along
/// with the rest of the process.
Future<BackendConnection> bootstrapLocalBackend({String? databasePath}) async {
  final backend = await EmbeddedBackend.start(databasePath: databasePath);
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
      return bootstrapLocalBackend(databasePath: databasePath);
    },
  );
}
