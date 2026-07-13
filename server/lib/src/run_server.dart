import 'dart:io';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'configuration/server_config.dart';

/// Binds and serves the shared API handler. Returns the live server so
/// callers (tests, the daemon wrapper in v0.6) can inspect the bound port
/// and close it.
Future<HttpServer> runServer(ServerConfig config) async {
  final handler = buildApiHandler(
    ApiServerConfig(
      backendKind: BackendKind.standalone,
      authToken: config.token,
    ),
  );

  final server = await shelf_io.serve(handler, config.host, config.port);
  // The "listening on" line is machine-read by the conformance harness and
  // service tooling; keep its format stable.
  stdout.writeln(
    'quadrant_server listening on http://${config.host}:${server.port}',
  );
  return server;
}
