import 'dart:io';

/// Delivery adapter for desktop notifications. The agent talks to this
/// interface; platforms plug in their mechanism.
abstract interface class DesktopNotifier {
  /// Shows a notification. Returns true when delivery is believed to
  /// have reached the desktop; false lets the scheduler retry later.
  Future<bool> notify({required String summary, required String body});
}

/// Linux adapter: `notify-send` speaks to any XDG desktop notification
/// service (mako, dunst, …) over D-Bus without linking libnotify.
class NotifySendNotifier implements DesktopNotifier {
  const NotifySendNotifier({this.appName = 'Quadrant Todo'});

  final String appName;

  @override
  Future<bool> notify({required String summary, required String body}) async {
    try {
      final result = await Process.run(
        'notify-send',
        ['--app-name', appName, summary, body],
      );
      return result.exitCode == 0;
    } on ProcessException {
      return false; // notify-send not installed; retried next tick.
    }
  }
}

/// Fallback adapter: logs to the journal (stdout under systemd). Used
/// when no desktop notification service is reachable.
class LogNotifier implements DesktopNotifier {
  const LogNotifier([this._log]);

  final void Function(String line)? _log;

  @override
  Future<bool> notify({required String summary, required String body}) async {
    (_log ?? stdout.writeln)('[notification] $summary — $body');
    return true;
  }
}
