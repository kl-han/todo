import 'package:quadrant_domain/quadrant_domain.dart' show EntityId;

import '../events/usage_event.dart';
import '../privacy/privacy_policy.dart';
import 'usage_interval.dart';

/// The event-driven interval state machine. No polling: an interval
/// opens when a recordable application takes focus and closes on the
/// next focus change, idle threshold, lock/suspend, collector stop, or
/// policy change. Closed intervals go to [onIntervalClosed]; there is no
/// other output.
///
/// Durations are monotonic differences clamped at zero; wall clocks are
/// carried for reporting only. An in-flight interval lives only in
/// memory — a crash discards it, which is the safe recovery choice
/// ("recover or discard incomplete interval safely").
class UsageRecorder {
  UsageRecorder({
    required this.deviceId,
    required this.platform,
    required this.source,
    required this.onIntervalClosed,
    PrivacyPolicy policy = const PrivacyPolicy(),
  }) : _policy = policy;

  final String deviceId;
  final String platform;
  final String source;
  final void Function(UsageInterval interval) onIntervalClosed;

  PrivacyPolicy _policy;

  _OpenInterval? _open;

  /// The application that would be recording if the session were not
  /// blanked/idle; lets recording resume on unlock without guessing.
  FocusChanged? _lastFocus;

  bool _blanked = false;
  bool _idle = false;

  PrivacyPolicy get policy => _policy;

  bool get hasOpenInterval => _open != null;

  /// Applies a policy change immediately: an interval that the new
  /// policy forbids closes now (private mode, pause, exclusion).
  void updatePolicy(
    PrivacyPolicy policy, {
    required DateTime at,
    required int monotonicMs,
  }) {
    _policy = policy;
    final open = _open;
    if (open != null && !policy.allowsRecording(open.applicationId, at)) {
      _close(at, monotonicMs);
    }
    // A newly-allowed policy resumes on the current focus.
    if (_open == null && !_blanked && !_idle) {
      _maybeOpenFrom(_lastFocus, at, monotonicMs);
    }
  }

  void handle(UsageEvent event) {
    switch (event) {
      case FocusChanged():
        _lastFocus = event;
        _close(event.at, event.monotonicMs);
        if (!_blanked && !_idle) {
          _maybeOpenFrom(event, event.at, event.monotonicMs);
        }
      case IdleStarted():
        _idle = true;
        _close(event.at, event.monotonicMs);
      case ActivityResumed():
        _idle = false;
        if (!_blanked) {
          _maybeOpenFrom(_lastFocus, event.at, event.monotonicMs);
        }
      case SessionBlanked():
        _blanked = true;
        _close(event.at, event.monotonicMs);
      case SessionRestored():
        _blanked = false;
        // Wait for the next FocusChanged rather than assuming the same
        // application still holds focus.
        _lastFocus = null;
      case CollectorStopped():
        _close(event.at, event.monotonicMs);
        _lastFocus = null;
    }
  }

  void _maybeOpenFrom(FocusChanged? focus, DateTime at, int monotonicMs) {
    if (focus == null) return;
    if (!_policy.allowsRecording(focus.applicationId, at)) return;
    _open = _OpenInterval(
      applicationId: focus.applicationId,
      applicationName: focus.applicationName,
      windowTitle: _policy.collectWindowTitles ? focus.windowTitle : null,
      startedAt: at,
      startedMonotonicMs: monotonicMs,
    );
  }

  void _close(DateTime at, int monotonicMs) {
    final open = _open;
    if (open == null) return;
    _open = null;
    final elapsedMs = monotonicMs - open.startedMonotonicMs;
    final activeSeconds = elapsedMs < 0 ? 0 : elapsedMs ~/ 1000;
    if (activeSeconds == 0) return; // sub-second flicker: not a record
    onIntervalClosed(UsageInterval(
      id: EntityId.generate(),
      deviceId: deviceId,
      platform: platform,
      applicationId: open.applicationId,
      applicationName: open.applicationName,
      startedAt: open.startedAt,
      endedAt: at,
      activeSeconds: activeSeconds,
      source: source,
      windowTitle: open.windowTitle,
    ));
  }
}

class _OpenInterval {
  const _OpenInterval({
    required this.applicationId,
    required this.applicationName,
    required this.windowTitle,
    required this.startedAt,
    required this.startedMonotonicMs,
  });

  final String applicationId;
  final String applicationName;
  final String? windowTitle;
  final DateTime startedAt;
  final int startedMonotonicMs;
}
