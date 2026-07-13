import 'package:quadrant_domain/quadrant_domain.dart';

import '../errors.dart';
import '../repositories.dart';

/// State filter for reminder queries.
enum ReminderFilter {
  pending,
  scheduled,
  delivered,
  dismissed,
  all;

  static ReminderFilter fromWire(String value) => switch (value) {
        'pending' => pending,
        'scheduled' => scheduled,
        'delivered' => delivered,
        'dismissed' => dismissed,
        'all' => all,
        _ => throw ArgumentError.value(value, 'state'),
      };

  bool matches(ReminderState state) =>
      this == all || name == state.wireName;
}

/// A reminder with its effective trigger, recomputed from the referenced
/// task/occurrence on every read. Null when the referenced side no longer
/// exists (e.g. the due date was cleared after the reminder was created).
typedef ResolvedReminder = ({Reminder reminder, DateTime? effectiveTriggerAt});

/// Reminder commands and queries. The backend stores intent and delivery
/// state; platform adapters register the OS notification and report back
/// via [update]. Recovery after reboot, restart, or timezone change is:
/// query [list] with a horizon, discard stale platform ids (state →
/// pending), reschedule, and record the new platform id — effective
/// triggers are always recomputed, never cached.
class ReminderService {
  ReminderService(this._reminders, this._tasks, this._recurrence,
      {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final ReminderRepository _reminders;
  final TaskRepository _tasks;
  final RecurrenceRepository _recurrence;
  final DateTime Function() _clock;

  ResolvedReminder create({
    String? taskId,
    String? occurrenceId,
    required ReminderTrigger trigger,
    DateTime? triggerAtUtc,
    int? offsetMinutes,
    String channel = 'notification',
  }) {
    if (channel != 'notification') {
      throw DomainValidationError('Unknown channel "$channel".');
    }
    final now = _clock();
    final reminder = Reminder(
      id: EntityId.generate(),
      taskId: taskId,
      occurrenceId: occurrenceId,
      trigger: trigger,
      triggerAtUtc: triggerAtUtc,
      offsetMinutes: offsetMinutes,
      channel: channel,
      createdAt: now,
      updatedAt: now,
    );
    _requireReference(reminder);
    if (trigger != ReminderTrigger.absolute &&
        _effectiveTriggerAt(reminder) == null) {
      throw DomainValidationError(
        'A relative reminder requires the referenced side to be a '
        'date-time; date-only values take absolute reminders.',
      );
    }
    _reminders.insert(reminder);
    return (reminder: reminder, effectiveTriggerAt: _effectiveTriggerAt(reminder));
  }

  ResolvedReminder get(String id) {
    final reminder = _reminders.findById(id);
    if (reminder == null) {
      throw EntityNotFoundException('No reminder $id.');
    }
    return (
      reminder: reminder,
      effectiveTriggerAt: _effectiveTriggerAt(reminder)
    );
  }

  /// Reminders matching [state], optionally only those whose effective
  /// trigger is at or before [until]. Ascending by effective trigger
  /// (unresolvable triggers last), then id.
  List<ResolvedReminder> list({
    ReminderFilter state = ReminderFilter.all,
    DateTime? until,
  }) {
    final resolved = [
      for (final reminder in _reminders.list())
        if (state.matches(reminder.state))
          (
            reminder: reminder,
            effectiveTriggerAt: _effectiveTriggerAt(reminder)
          ),
    ];
    final filtered = until == null
        ? resolved
        : [
            for (final entry in resolved)
              if (entry.effectiveTriggerAt != null &&
                  !entry.effectiveTriggerAt!.isAfter(until))
                entry,
          ];
    filtered.sort((a, b) {
      final at = a.effectiveTriggerAt;
      final bt = b.effectiveTriggerAt;
      if ((at == null) != (bt == null)) return at == null ? 1 : -1;
      if (at != null) {
        final byTime = at.compareTo(bt!);
        if (byTime != 0) return byTime;
      }
      return a.reminder.id.compareTo(b.reminder.id);
    });
    return filtered;
  }

  /// Advances delivery state and/or records the platform schedule id.
  /// Setting `pending` without an explicit platform id clears the stored
  /// one — that is the "discard stale schedule" step of recovery.
  ResolvedReminder update(
    String id, {
    ReminderState? state,
    bool platformScheduleIdProvided = false,
    String? platformScheduleId,
    int? expectedVersion,
  }) {
    var reminder = _reminders.findById(id);
    if (reminder == null) {
      throw EntityNotFoundException('No reminder $id.');
    }
    _checkVersion(reminder.version, expectedVersion);
    if (state == null && !platformScheduleIdProvided) {
      return (
        reminder: reminder,
        effectiveTriggerAt: _effectiveTriggerAt(reminder)
      );
    }
    final clearsPlatformId =
        state == ReminderState.pending && !platformScheduleIdProvided;
    reminder = reminder.withState(
      _clock(),
      state: state ?? reminder.state,
      platformScheduleId: platformScheduleIdProvided
          ? () => platformScheduleId
          : (clearsPlatformId ? () => null : null),
    );
    _reminders.update(reminder);
    return (
      reminder: reminder,
      effectiveTriggerAt: _effectiveTriggerAt(reminder)
    );
  }

  void delete(String id, {int? expectedVersion}) {
    final reminder = _reminders.findById(id);
    if (reminder == null) {
      throw EntityNotFoundException('No reminder $id.');
    }
    _checkVersion(reminder.version, expectedVersion);
    _reminders.delete(id);
  }

  // ---- internals ----

  void _requireReference(Reminder reminder) {
    final taskId = reminder.taskId;
    if (taskId != null) {
      final task = _tasks.findById(taskId);
      if (task == null || task.isDeleted) {
        throw EntityNotFoundException('No task $taskId.');
      }
      return;
    }
    if (_recurrence.findOccurrenceById(reminder.occurrenceId!) == null) {
      throw EntityNotFoundException(
          'No occurrence ${reminder.occurrenceId}.');
    }
  }

  DateTime? _effectiveTriggerAt(Reminder reminder) {
    if (reminder.trigger == ReminderTrigger.absolute) {
      return reminder.triggerAtUtc;
    }
    final referencedInstant = _referencedInstant(reminder);
    return referencedInstant
        ?.subtract(Duration(minutes: reminder.offsetMinutes!));
  }

  DateTime? _referencedInstant(Reminder reminder) {
    final taskId = reminder.taskId;
    if (taskId != null) {
      final task = _tasks.findById(taskId);
      if (task == null || task.isDeleted) return null;
      return reminder.trigger == ReminderTrigger.relativeStart
          ? task.schedule.startAtUtc
          : task.schedule.dueAtUtc;
    }
    final occurrence = _recurrence.findOccurrenceById(reminder.occurrenceId!);
    if (occurrence == null) return null;
    final matchesSide = switch (reminder.trigger) {
      ReminderTrigger.relativeStart => occurrence.kind == OccurrenceKind.start,
      ReminderTrigger.relativeDue => occurrence.kind == OccurrenceKind.due,
      ReminderTrigger.absolute => false,
    };
    return matchesSide ? occurrence.atUtc : null;
  }

  void _checkVersion(int current, int? expected) {
    if (expected != null && expected != current) {
      throw VersionConflictException(currentVersion: current);
    }
  }
}
