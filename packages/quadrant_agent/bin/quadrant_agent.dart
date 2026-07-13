import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:quadrant_agent/quadrant_agent.dart';

/// Default loopback port; overridable with --port. Registered nowhere —
/// purely a local convention, and the printed "listening on" line is the
/// source of truth.
const int defaultPort = 47821;

Future<int> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand(
      'run',
      ArgParser()
        ..addOption('port', defaultsTo: '$defaultPort')
        ..addOption('data-dir', help: 'Vault directory (default: XDG data).')
        ..addOption('config-dir',
            help: 'Token/lock directory (default: XDG config).')
        ..addOption('tick-seconds', defaultsTo: '30')
        ..addFlag('log-notifications',
            help: 'Write notifications to stdout instead of notify-send.'),
    )
    ..addCommand('status', ArgParser()..addOption('port', defaultsTo: '$defaultPort'));

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    return 64;
  }

  switch (results.command?.name) {
    case 'run':
      return _run(results.command!);
    case 'status':
      return _status(results.command!);
    default:
      stderr.writeln('Usage: quadrant_agent <run|status> [options]');
      return 64;
  }
}

String _defaultDir(String xdgVariable, String fallback) {
  final xdg = Platform.environment[xdgVariable];
  if (xdg != null && xdg.isNotEmpty) return '$xdg/quadrant-todo';
  final home = Platform.environment['HOME'] ?? '.';
  return '$home/$fallback/quadrant-todo';
}

Future<int> _run(ArgResults options) async {
  final dataDir =
      options['data-dir'] as String? ?? _defaultDir('XDG_DATA_HOME', '.local/share');
  final configDir =
      options['config-dir'] as String? ?? _defaultDir('XDG_CONFIG_HOME', '.config');

  final InstanceLock lock;
  try {
    lock = InstanceLock.acquire('$configDir/agent.lock');
  } on StateError catch (error) {
    stderr.writeln(error.message);
    return 1;
  }

  final credential = await AgentCredential.load('$configDir/agent-token');
  final host = AgentHost(
    databasePath: '$dataDir/default.sqlite3',
    token: credential.token,
    port: int.parse(options['port'] as String),
    tickInterval: Duration(seconds: int.parse(options['tick-seconds'] as String)),
    notifier:
        options['log-notifications'] as bool ? const LogNotifier() : null,
  );
  await host.start(
    onCorruptMovedAside: (movedTo) =>
        stderr.writeln('corrupt vault moved aside: $movedTo'),
  );
  // Machine-read by tooling; keep the format stable.
  stdout.writeln(
      'quadrant-agent listening on http://127.0.0.1:${host.boundPort}');
  stdout.writeln('vault: $dataDir/default.sqlite3');
  stdout.writeln('token file: ${credential.path}');

  final done = Completer<int>();
  for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    signal.watch().listen((_) async {
      if (done.isCompleted) return;
      await host.stop();
      lock.release();
      done.complete(0);
    });
  }
  return done.future;
}

Future<int> _status(ArgResults options) async {
  final port = int.parse(options['port'] as String);
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse('http://127.0.0.1:$port/api/v1/agent/status'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    stdout.writeln(body);
    return response.statusCode == 200 ? 0 : 1;
  } on SocketException {
    stderr.writeln('quadrant-agent is not running on port $port.');
    return 1;
  } finally {
    client.close();
  }
}
