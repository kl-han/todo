import 'package:quadrant_api_client/quadrant_api_client.dart';

import 'remote_profile.dart';

/// Result of probing a remote backend before (or after) committing to it.
/// Every check that ran reports individually so the settings UI can say
/// exactly what is wrong.
class RemoteDiagnostics {
  const RemoteDiagnostics({
    required this.reachable,
    this.authenticated = false,
    this.apiVersionSupported = false,
    this.vaultExists = false,
    this.detail,
  });

  final bool reachable;
  final bool authenticated;
  final bool apiVersionSupported;
  final bool vaultExists;

  /// Human-readable explanation of the first failed check.
  final String? detail;

  bool get ok =>
      reachable && authenticated && apiVersionSupported && vaultExists;
}

/// Probes a remote backend: reachability (health), credential validity and
/// API-version negotiation (capabilities), and vault existence. Never
/// throws — the outcome is data for the settings sheet.
Future<RemoteDiagnostics> diagnoseRemoteBackend(
  RemoteBackendProfile profile,
  String bearerToken,
) async {
  final client = QuadrantApiClient(
    baseUrl: profile.baseUrl,
    authorization: 'Bearer $bearerToken',
  );
  try {
    try {
      await client.health();
    } on ApiUnavailableException catch (error) {
      return RemoteDiagnostics(
        reachable: false,
        detail: 'Server unreachable: ${error.cause ?? profile.baseUrl}',
      );
    }

    final Capabilities capabilities;
    try {
      capabilities = await client.capabilities();
    } on ProblemDetailsException catch (problem) {
      return RemoteDiagnostics(
        reachable: true,
        detail: problem.status == 401
            ? 'The server rejected the credential.'
            : 'Capability check failed: ${problem.title}',
      );
    }
    if (!capabilities.supportsV1) {
      return RemoteDiagnostics(
        reachable: true,
        authenticated: true,
        detail: 'Server speaks API ${capabilities.apiVersion}, not v1.',
      );
    }

    final vaults = await client.listVaults();
    if (!vaults.contains(profile.vaultId)) {
      return RemoteDiagnostics(
        reachable: true,
        authenticated: true,
        apiVersionSupported: true,
        detail: 'Vault "${profile.vaultId}" does not exist on the server '
            '(available: ${vaults.join(', ')}).',
      );
    }

    return const RemoteDiagnostics(
      reachable: true,
      authenticated: true,
      apiVersionSupported: true,
      vaultExists: true,
    );
  } on ApiUnavailableException catch (error) {
    return RemoteDiagnostics(
      reachable: false,
      detail: 'Connection lost during diagnostics: ${error.cause}',
    );
  } finally {
    client.close();
  }
}
