/// Backend hosting for the Quadrant Todo application.
///
/// Local mode spawns [EmbeddedBackend] — a dedicated backend isolate that
/// owns the HTTP listener, REST routing, and (from v0.2) the SQLite
/// connection. Remote mode configures the same REST client from a
/// [RemoteBackendProfile]. The UI isolate never opens SQLite directly.
library;

export 'src/backend_lifecycle.dart';
export 'src/backend_settings.dart';
export 'src/credential_store.dart';
export 'src/diagnostics.dart';
export 'src/embedded_backend.dart';
export 'src/local_session_token.dart';
export 'src/remote_profile.dart';
