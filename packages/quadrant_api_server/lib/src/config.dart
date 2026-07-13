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
    this.authToken,
    this.schemaVersion = 0,
  });

  final BackendKind backendKind;

  /// Token required on every route except `/api/v1/health`. The embedded
  /// backend passes a random per-launch value (`Authorization: Local <t>`);
  /// the standalone server passes its persistent token
  /// (`Authorization: Bearer <t>`). When null, authentication is disabled
  /// (tests only).
  final String? authToken;

  /// Database schema version reported by the health route.
  final int schemaVersion;
}
