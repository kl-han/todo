import 'dart:io';

/// Daemon mode: re-exec this same server detached from the terminal and
/// return the child pid. Dart has no fork(2); a detached re-exec with an
/// internal marker flag is the portable equivalent. The child writes the
/// PID file and logs to its log file instead of stdout.
Future<int> daemonize(List<String> originalArguments) async {
  final childArgs = [
    ...originalArguments.where((argument) => argument != '--daemon'),
    '--_daemonized',
  ];

  final script = Platform.script.toFilePath();
  // Under `dart run` the executable is the Dart VM and needs the script
  // path; an AOT-compiled quadrant_server binary is its own script.
  final viaVm = script.endsWith('.dart');
  final process = await Process.start(
    Platform.resolvedExecutable,
    viaVm ? ['run', script, ...childArgs] : childArgs,
    mode: ProcessStartMode.detached,
  );
  return process.pid;
}
