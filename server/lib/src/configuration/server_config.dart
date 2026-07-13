import 'package:args/args.dart';

/// Command-line configuration for the standalone server.
///
/// v0.1 intentionally supports only foreground operation; daemon mode, PID
/// files, and vault management arrive in v0.6.
class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    this.token,
  });

  /// Bind address. Defaults to loopback; exposing the server further is an
  /// explicit operator decision.
  final String host;

  /// TCP port; 0 lets the OS choose (used by tests and printed on startup).
  final int port;

  /// Persistent bearer token. When omitted the server refuses data routes
  /// only if a token is configured; v0.6 makes authentication mandatory.
  final String? token;

  static ArgParser buildParser() => ArgParser()
    ..addOption('host', defaultsTo: '127.0.0.1', help: 'Bind address.')
    ..addOption('port', defaultsTo: '8787', help: 'TCP port (0 = ephemeral).')
    ..addOption('token', help: 'Bearer token required on data routes.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  static ServerConfig fromArgs(ArgResults results) => ServerConfig(
        host: results['host'] as String,
        port: int.parse(results['port'] as String),
        token: results['token'] as String?,
      );
}
