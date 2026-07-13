/// Standalone Quadrant Todo backend.
///
/// Serves exactly the same REST handler as the embedded backend; only
/// hosting concerns (address, port, persistent token, process lifetime)
/// live here.
library;

export 'src/configuration/server_config.dart';
export 'src/run_server.dart';
