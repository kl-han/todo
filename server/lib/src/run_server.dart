import 'dart:io';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:quadrant_store/quadrant_store.dart' show schemaVersion;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'configuration/server_config.dart';
import 'vaults/vault_manager.dart';

/// A live standalone server and the resources it owns.
class RunningServer {
  RunningServer(this._httpServer, this._vaults);

  final HttpServer _httpServer;
  final VaultManager _vaults;

  int get port => _httpServer.port;

  Future<void> close() async {
    // force: idle keep-alive connections must not block shutdown; every
    // acknowledged write is already committed.
    await _httpServer.close(force: true);
    _vaults.closeAll();
  }
}

/// Binds and serves the shared API handler over the vault directory.
Future<RunningServer> runServer(
  ServerConfig config, {
  void Function(String line)? log,
}) async {
  final emit = log ?? stdout.writeln;

  if (config.token == null && !config.allowAnonymous) {
    throw ArgumentError(
      'A bearer token is required: pass --token/--token-file, or opt out '
      'explicitly with --allow-anonymous (development only).',
    );
  }

  final vaults = VaultManager(config.dataDir);
  final handler = buildApiHandler(
    ApiServerConfig(
      backendKind: BackendKind.standalone,
      authToken: config.token,
      schemaVersion: schemaVersion,
      vaults: vaults.resolve,
      listVaults: vaults.list,
    ),
  );

  final server = await shelf_io.serve(handler, config.host, config.port);
  // The "listening on" line is machine-read by the conformance harness and
  // service tooling; keep its format stable.
  emit('quadrant_server listening on http://${config.host}:${server.port}');
  emit('vault directory: ${config.dataDir}');
  return RunningServer(server, vaults);
}
