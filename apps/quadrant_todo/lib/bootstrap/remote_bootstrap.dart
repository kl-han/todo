import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// Remote mode startup: point the same typed client at a standalone server.
///
/// There is no embedded backend and no fallback — if the server is
/// unreachable the caller surfaces an explicit offline state. Credential
/// lookup from platform secure storage arrives in v0.7; until then the
/// token is passed in directly.
Future<BackendConnection> bootstrapRemoteBackend({
  required RemoteBackendProfile profile,
  required String bearerToken,
}) async {
  final client = QuadrantApiClient(
    baseUrl: profile.baseUrl,
    authorization: 'Bearer $bearerToken',
  );
  await client.waitUntilHealthy();

  return BackendConnection(mode: BackendMode.remote, client: client);
}
