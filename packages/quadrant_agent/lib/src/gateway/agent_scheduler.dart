import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';

import 'desktop_notifier.dart';

/// The agent's periodic work: deliver due reminders and announce focus
/// completions. [tick] is idempotent per event — a reminder is marked
/// delivered only after the notifier accepted it, and a focus completion
/// is announced at most once per session — so a crashed or delayed tick
/// can never double-notify, and a failed delivery retries next tick.
///
/// One tick per interval (≤ every 30 seconds per the resource goals);
/// between ticks the agent is idle.
class AgentScheduler {
  AgentScheduler(
    this._services,
    this._notifier, {
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final AppServices _services;
  final DesktopNotifier _notifier;
  final DateTime Function() _clock;

  final Set<String> _announcedSessions = {};

  DateTime? lastTickAt;

  /// Runs one scheduler pass; returns the number of notifications
  /// delivered.
  Future<int> tick() async {
    final now = _clock();
    lastTickAt = now;
    return await _deliverDueReminders(now) + await _announceFocus(now);
  }

  /// The agent IS the desktop delivery adapter, so due pending reminders
  /// go straight to delivered once the desktop accepted the notification.
  /// Bodies stay generic on purpose: titles may be private, and the
  /// fallback notifier writes bodies to the journal.
  Future<int> _deliverDueReminders(DateTime now) async {
    var delivered = 0;
    for (final resolved in _services.reminders.list(until: now)) {
      final reminder = resolved.reminder;
      if (reminder.state != ReminderState.pending &&
          reminder.state != ReminderState.scheduled) {
        continue;
      }
      final accepted = await _notifier.notify(
        summary: 'Quadrant reminder',
        body: switch (reminder.trigger) {
          ReminderTrigger.absolute => 'A scheduled reminder is due.',
          ReminderTrigger.relativeStart => 'A task is about to start.',
          ReminderTrigger.relativeDue => 'A task is almost due.',
        },
      );
      if (!accepted) continue; // retry next tick
      _services.reminders.update(
        reminder.id,
        state: ReminderState.delivered,
        expectedVersion: reminder.version,
      );
      delivered += 1;
    }
    return delivered;
  }

  /// Announces (once) that the active session's planned focus time is
  /// reached, counting the live portion of the current running phase.
  Future<int> _announceFocus(DateTime now) async {
    final session = _services.focus.list(active: true).firstOrNull;
    if (session == null) {
      _announcedSessions.clear();
      return 0;
    }
    if (session.phase != FocusPhase.running ||
        _announcedSessions.contains(session.id) ||
        session.activeSeconds + session.elapsedInPhase(now) <
            session.plannedFocusSeconds) {
      return 0;
    }
    final minutes = session.plannedFocusSeconds ~/ 60;
    final accepted = await _notifier.notify(
      summary: 'Focus session complete',
      body: 'Your planned $minutes-minute focus block is done. '
          'Record the result when ready.',
    );
    if (!accepted) return 0;
    _announcedSessions.add(session.id);
    return 1;
  }
}
