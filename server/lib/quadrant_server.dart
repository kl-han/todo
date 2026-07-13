/// Standalone Quadrant Todo backend.
///
/// Serves exactly the same REST handler as the embedded backend; only
/// hosting concerns (address, port, tokens, daemon lifecycle, vault
/// files) live here.
library;

export 'src/configuration/server_config.dart';
export 'src/daemon/daemonizer.dart';
export 'src/run_server.dart';
export 'src/vaults/vault_manager.dart';
