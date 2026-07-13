/// The Quadrant personal agent: a per-user, unprivileged process that
/// hosts the local backend, owns the Pomodoro timer, and delivers desktop
/// reminders — so closing the GUI never cancels anything.
///
/// See ADR-0006 and the post-v1 design section: event-driven, loopback
/// only, no root, no raw input access.
library;

export 'src/gateway/agent_scheduler.dart';
export 'src/gateway/desktop_notifier.dart';
export 'src/lifecycle/agent_credential.dart';
export 'src/lifecycle/instance_lock.dart';
export 'src/local_api/agent_host.dart';
