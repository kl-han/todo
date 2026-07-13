import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:quadrant_server/quadrant_server.dart';
import 'package:quadrant_store/quadrant_store.dart';

Future<void> main(List<String> arguments) async {
  final parser = ServerConfig.buildParser();
  final results = parser.parse(arguments);
  if (results['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final command = results.rest.isEmpty ? 'serve' : results.rest.first;
  final config = ServerConfig.fromArgs(results);

  switch (command) {
    case 'serve':
      await _serve(config, arguments);
    case 'vault-create':
      _vaultCreate(config, results.rest.skip(1).toList());
    case 'backup':
      _backup(config, results.rest.skip(1).toList());
    default:
      stderr.writeln('Unknown command "$command".\n');
      _printUsage(parser);
      exitCode = 64;
  }
}

Future<void> _serve(ServerConfig config, List<String> arguments) async {
  if (config.daemon && !config.daemonized) {
    final pid = await daemonize(arguments);
    stdout.writeln('quadrant_server daemon starting (pid $pid)');
    stdout.writeln('pid file: ${config.pidFile}');
    stdout.writeln('log file: ${config.logFile}');
    return;
  }

  IOSink? logSink;
  void Function(String)? log;
  if (config.daemonized) {
    final logFile = File(config.logFile!);
    logFile.parent.createSync(recursive: true);
    logSink = logFile.openWrite(mode: FileMode.append);
    log = (line) => logSink!.writeln('${DateTime.now().toUtc()} $line');

    final pidFile = File(config.pidFile!);
    pidFile.parent.createSync(recursive: true);
    pidFile.writeAsStringSync('$pid\n');
  }

  final server = await runServer(config, log: log);

  // Foreground and daemon alike: run until SIGINT/SIGTERM, close cleanly.
  // Both subscriptions must be cancelled afterwards or the still-active
  // watcher keeps the event loop (and the process) alive forever.
  final stopped = Completer<ProcessSignal>();
  final subscriptions = [
    for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm])
      signal.watch().listen((received) {
        if (!stopped.isCompleted) stopped.complete(received);
      }),
  ];
  await stopped.future;
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
  (log ?? stdout.writeln)('quadrant_server shutting down');
  await server.close();
  if (config.daemonized) {
    final pidFile = File(config.pidFile!);
    if (pidFile.existsSync()) pidFile.deleteSync();
  }
  await logSink?.flush();
  await logSink?.close();
}

void _vaultCreate(ServerConfig config, List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: quadrant_server vault-create <name>');
    exitCode = 64;
    return;
  }
  final manager = VaultManager(config.dataDir);
  manager.create(args.single);
  stdout.writeln('created vault "${args.single}" '
      'at ${manager.pathFor(args.single)}');
}

void _backup(ServerConfig config, List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Usage: quadrant_server backup <vault> <destination>');
    exitCode = 64;
    return;
  }
  final [vault, destination] = args;
  final manager = VaultManager(config.dataDir);
  final source = File(manager.pathFor(vault));
  if (!VaultManager.isValidName(vault) || !source.existsSync()) {
    stderr.writeln('No vault "$vault" under ${config.dataDir}.');
    exitCode = 66;
    return;
  }
  final database = QuadrantDatabase.open(source.path);
  try {
    database.backupTo(destination);
  } finally {
    database.close();
  }
  // A backup nobody verified is a hope, not a backup.
  final problem = QuadrantDatabase.verifySnapshot(destination);
  if (problem != null) {
    stderr.writeln('backup verification FAILED: $problem');
    exitCode = 70;
    return;
  }
  stdout.writeln('backed up vault "$vault" to $destination (verified)');
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Quadrant Todo standalone server.\n');
  stdout.writeln('Commands:');
  stdout.writeln('  serve (default)              Run the server.');
  stdout.writeln('  vault-create <name>          Create an empty vault.');
  stdout.writeln('  backup <vault> <dest>        Snapshot a vault.\n');
  stdout.writeln(parser.usage);
}
