import 'dart:io';

import 'package:quadrant_server/quadrant_server.dart';

Future<void> main(List<String> arguments) async {
  final parser = ServerConfig.buildParser();
  final results = parser.parse(arguments);
  if (results['help'] as bool) {
    stdout.writeln('Quadrant Todo standalone server.\n');
    stdout.writeln(parser.usage);
    return;
  }

  final server = await runServer(ServerConfig.fromArgs(results));

  // Foreground mode: run until interrupted, then close cleanly.
  final signals = [ProcessSignal.sigint, ProcessSignal.sigterm];
  await Future.any(signals.map((s) => s.watch().first));
  stdout.writeln('quadrant_server shutting down');
  await server.close();
}
