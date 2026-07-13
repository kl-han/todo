import 'dart:io';

import 'package:args/args.dart';

/// Command-line configuration for the standalone server.
///
/// Commands:
///
///     quadrant_server serve [--daemon] [options]     (default)
///     quadrant_server vault-create NAME
///     quadrant_server backup VAULT DESTINATION
class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.dataDir,
    this.token,
    this.allowAnonymous = false,
    this.daemon = false,
    this.daemonized = false,
    this.pidFile,
    this.logFile,
  });

  /// Bind address. Defaults to loopback; exposing the server further is an
  /// explicit operator decision.
  final String host;

  /// TCP port; 0 lets the OS choose (used by tests and printed on startup).
  final int port;

  /// Directory holding one `<vault>.sqlite3` per vault.
  final String dataDir;

  /// Persistent bearer token required on data routes. Mandatory unless
  /// [allowAnonymous] is set explicitly.
  final String? token;

  /// Development escape hatch: serve without authentication. Never use on
  /// a network-exposed host.
  final bool allowAnonymous;

  /// Operator asked for daemon mode: re-exec detached and exit.
  final bool daemon;

  /// This process IS the detached daemon child (internal flag).
  final bool daemonized;

  final String? pidFile;
  final String? logFile;

  static String defaultDataDir() {
    final dataHome = Platform.environment['XDG_DATA_HOME'] ??
        '${Platform.environment['HOME'] ?? '.'}/.local/share';
    return '$dataHome/quadrant-todo/vaults';
  }

  static String defaultRuntimeDir() {
    return Platform.environment['XDG_RUNTIME_DIR'] ?? '/tmp';
  }

  static ArgParser buildParser() => ArgParser()
    ..addOption('host', defaultsTo: '127.0.0.1', help: 'Bind address.')
    ..addOption('port', defaultsTo: '8787', help: 'TCP port (0 = ephemeral).')
    ..addOption(
      'data-dir',
      help: 'Vault directory '
          '(default: XDG data dir/quadrant-todo/vaults).',
    )
    ..addOption('token', help: 'Bearer token required on data routes.')
    ..addOption(
      'token-file',
      help: 'File containing the bearer token (preferred over --token, '
          'which leaks into process listings).',
    )
    ..addFlag(
      'allow-anonymous',
      negatable: false,
      help: 'Serve without authentication (development only).',
    )
    ..addFlag('daemon', negatable: false, help: 'Run in the background.')
    ..addFlag('_daemonized', negatable: false, hide: true)
    ..addOption('pid-file',
        help: 'PID file (daemon mode; default: XDG runtime dir).')
    ..addOption('log-file',
        help: 'Log file (daemon mode; default: alongside data dir).')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  static ServerConfig fromArgs(ArgResults results) {
    var token = results['token'] as String?;
    final tokenFile = results['token-file'] as String?;
    if (token == null && tokenFile != null) {
      token = File(tokenFile).readAsStringSync().trim();
    }
    final dataDir = results['data-dir'] as String? ?? defaultDataDir();
    return ServerConfig(
      host: results['host'] as String,
      port: int.parse(results['port'] as String),
      dataDir: dataDir,
      token: token,
      allowAnonymous: results['allow-anonymous'] as bool,
      daemon: results['daemon'] as bool,
      daemonized: results['_daemonized'] as bool,
      pidFile: results['pid-file'] as String? ??
          '${defaultRuntimeDir()}/quadrant-server.pid',
      logFile: results['log-file'] as String? ??
          '$dataDir/../quadrant-server.log',
    );
  }
}
