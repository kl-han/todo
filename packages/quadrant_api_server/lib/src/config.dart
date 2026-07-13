import 'package:quadrant_application/quadrant_application.dart';

/// Which kind of process is serving the API. Reported by `/api/v1/health`
/// so clients and tests can tell the two apart without behavioral
/// differences existing anywhere else.
enum BackendKind {
  embedded,
  standalone;

  String get wireName => name;
}

/// Configuration shared by every backend that serves the REST API.
class ApiServerConfig {
  const ApiServerConfig({
    required this.backendKind,
    required this.vaults,
    this.listVaults = _defaultVaultList,
    this.authToken,
    this.schemaVersion = 0,
  });

  final BackendKind backendKind;

  /// Resolves a vault id to its application services, or null when the
  /// vault does not exist. The embedded backend exposes a single vault
  /// named `default`; the standalone server may host several.
  final AppServices? Function(String vaultId) vaults;

  /// Names of the accessible vaults, served by `GET /api/v1/vaults`.
  /// Defaults to just `default`, which is correct for the embedded
  /// backend; the standalone server passes its vault manager's list.
  final List<String> Function() listVaults;

  static List<String> _defaultVaultList() => const ['default'];

  /// Token required on every route except `/api/v1/health`. The embedded
  /// backend passes a random per-launch value (`Authorization: Local <t>`);
  /// the standalone server passes its persistent token
  /// (`Authorization: Bearer <t>`). When null, authentication is disabled
  /// (tests only).
  final String? authToken;

  /// Database schema version reported by the health route.
  final int schemaVersion;
}
