import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// The configured server answers, but not with a v1 API this build can
/// talk to. Surfaced as a hard error — never silently degraded.
class IncompatibleBackendException implements Exception {
  IncompatibleBackendException(this.apiVersion);

  final String apiVersion;

  @override
  String toString() =>
      'IncompatibleBackendException: server speaks API "$apiVersion", '
      'this build requires v1';
}

/// Remote mode startup: point the same typed client at a standalone
/// server and negotiate capabilities.
///
/// There is no embedded backend and no fallback. If the server is
/// unreachable the connection is still returned — the UI presents the
/// explicit offline state and retries — but an incompatible API version
/// throws, because retrying cannot fix it.
Future<BackendConnection> bootstrapRemoteBackend({
  required RemoteBackendProfile profile,
  required String bearerToken,
}) async {
  final client = QuadrantApiClient(
    baseUrl: profile.baseUrl.resolve('/'),
    authorization: 'Bearer $bearerToken',
  );

  try {
    await client.waitUntilHealthy(timeout: const Duration(seconds: 3));
    final capabilities = await client.capabilities();
    if (!capabilities.supportsV1) {
      client.close();
      throw IncompatibleBackendException(capabilities.apiVersion);
    }
  } on ApiUnavailableException {
    // Offline at boot: keep the connection; AppState.refresh will show
    // the explicit offline banner and the user can retry or reconfigure.
  }

  return BackendConnection(mode: BackendMode.remote, client: client);
}
