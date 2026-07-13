/// One observation from a platform collector. Every event carries the
/// wall clock (for calendar reporting) and a monotonic timestamp (for
/// duration arithmetic) — wall-clock jumps must never distort durations.
sealed class UsageEvent {
  const UsageEvent({required this.at, required this.monotonicMs});

  /// Wall-clock instant (UTC).
  final DateTime at;

  /// Milliseconds on a monotonic clock (e.g. a `Stopwatch` started with
  /// the collector). Only differences are meaningful.
  final int monotonicMs;
}

/// The foreground application changed.
class FocusChanged extends UsageEvent {
  const FocusChanged({
    required super.at,
    required super.monotonicMs,
    required this.applicationId,
    this.applicationName = '',
    this.windowTitle,
  });

  /// Stable identifier: Wayland `app_id`, X11 class, or executable name.
  final String applicationId;

  final String applicationName;

  /// Only forwarded when title collection is explicitly enabled; the
  /// recorder additionally drops it unless the policy allows titles.
  final String? windowTitle;
}

/// No input for the configured idle threshold; the active interval ends
/// at the threshold boundary, not at detection time.
class IdleStarted extends UsageEvent {
  const IdleStarted({required super.at, required super.monotonicMs});
}

/// Input resumed after idle.
class ActivityResumed extends UsageEvent {
  const ActivityResumed({required super.at, required super.monotonicMs});
}

/// Session locked, or the system is about to suspend.
class SessionBlanked extends UsageEvent {
  const SessionBlanked({required super.at, required super.monotonicMs});
}

/// Session unlocked / system resumed. Recording restarts on the next
/// [FocusChanged], never speculatively.
class SessionRestored extends UsageEvent {
  const SessionRestored({required super.at, required super.monotonicMs});
}

/// The collector is going away (compositor shutdown, agent stop).
class CollectorStopped extends UsageEvent {
  const CollectorStopped({required super.at, required super.monotonicMs});
}
