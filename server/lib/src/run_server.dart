import 'dart:io';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_store/quadrant_store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'configuration/server_config.dart';

/// A live standalone server and the resources it owns.
class RunningServer {
  RunningServer(this._httpServer, this._database);

  final HttpServer _httpServer;
  final QuadrantDatabase _database;

  int get port => _httpServer.port;

  Future<void> close() async {
    await _httpServer.close();
    _database.close();
  }
}

/// Opens the vault database, binds, and serves the shared API handler.
Future<RunningServer> runServer(ServerConfig config) async {
  final database = QuadrantDatabase.open(config.databasePath);
  final services = AppServices(
    taskRepository: SqliteTaskRepository(database),
    tagRepository: SqliteTagRepository(database),
  );

  final handler = buildApiHandler(
    ApiServerConfig(
      backendKind: BackendKind.standalone,
      authToken: config.token,
      schemaVersion: database.userVersion,
      vaults: (vaultId) => vaultId == 'default' ? services : null,
    ),
  );

  final server = await shelf_io.serve(handler, config.host, config.port);
  // The "listening on" line is machine-read by the conformance harness and
  // service tooling; keep its format stable.
  stdout.writeln(
    'quadrant_server listening on http://${config.host}:${server.port}',
  );
  return RunningServer(server, database);
}
