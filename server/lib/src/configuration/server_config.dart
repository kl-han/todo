import 'dart:io';

import 'package:args/args.dart';

/// Command-line configuration for the standalone server.
///
/// v0.2 serves a single vault named `default`; daemon mode, PID files, and
/// multi-vault management arrive in v0.6.
class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.databasePath,
    this.token,
  });

  /// Bind address. Defaults to loopback; exposing the server further is an
  /// explicit operator decision.
  final String host;

  /// TCP port; 0 lets the OS choose (used by tests and printed on startup).
  final int port;

  /// SQLite file of the `default` vault.
  final String databasePath;

  /// Persistent bearer token required on data routes. Optional until v0.6
  /// makes authentication mandatory.
  final String? token;

  static String defaultDatabasePath() {
    final dataHome = Platform.environment['XDG_DATA_HOME'] ??
        '${Platform.environment['HOME'] ?? '.'}/.local/share';
    return '$dataHome/quadrant-todo/vaults/default.sqlite3';
  }

  static ArgParser buildParser() => ArgParser()
    ..addOption('host', defaultsTo: '127.0.0.1', help: 'Bind address.')
    ..addOption('port', defaultsTo: '8787', help: 'TCP port (0 = ephemeral).')
    ..addOption(
      'database',
      help: 'SQLite file of the default vault '
          '(default: XDG data dir/quadrant-todo/vaults/default.sqlite3).',
    )
    ..addOption('token', help: 'Bearer token required on data routes.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  static ServerConfig fromArgs(ArgResults results) => ServerConfig(
        host: results['host'] as String,
        port: int.parse(results['port'] as String),
        databasePath:
            results['database'] as String? ?? defaultDatabasePath(),
        token: results['token'] as String?,
      );
}
