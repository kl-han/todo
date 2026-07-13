import '../rules/validation.dart';

/// How a reminder's trigger instant is defined.
enum ReminderTrigger {
  absolute,
  relativeStart('relative_start'),
  relativeDue('relative_due');

  const ReminderTrigger([this._wire]);

  final String? _wire;

  String get wireName => _wire ?? name;

  static ReminderTrigger fromWire(String value) => switch (value) {
        'absolute' => absolute,
        'relative_start' => relativeStart,
        'relative_due' => relativeDue,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown trigger type'),
      };
}

/// Delivery lifecycle. `pending` means "needs (re)scheduling with the
/// platform"; recovery resets stale `scheduled` reminders to `pending`.
enum ReminderState {
  pending,
  scheduled,
  delivered,
  dismissed;

  String get wireName => name;

  static ReminderState fromWire(String value) => switch (value) {
        'pending' => pending,
        'scheduled' => scheduled,
        'delivered' => delivered,
        'dismissed' => dismissed,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown reminder state'),
      };
}

/// A reminder record — separate from the task and from recurrence. The
/// backend stores intent (trigger definition) and delivery state;
/// platform adapters own the actual OS notification and record its id in
/// [platformScheduleId].
class Reminder {
  Reminder({
    required this.id,
    required this.trigger,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.occurrenceId,
    this.triggerAtUtc,
    this.offsetMinutes,
    this.channel = 'notification',
    this.state = ReminderState.pending,
    this.platformScheduleId,
    this.version = 1,
  }) {
    if ((taskId == null) == (occurrenceId == null)) {
      throw DomainValidationError(
        'A reminder references exactly one of task_id and occurrence_id.',
      );
    }
    if (trigger == ReminderTrigger.absolute) {
      if (triggerAtUtc == null || offsetMinutes != null) {
        throw DomainValidationError(
          'An absolute reminder carries trigger_at_utc and no '
          'offset_minutes.',
        );
      }
      if (!triggerAtUtc!.isUtc) {
        throw DomainValidationError(
          'trigger_at_utc must be an absolute UTC instant.',
        );
      }
    } else {
      if (offsetMinutes == null || triggerAtUtc != null) {
        throw DomainValidationError(
          'A relative reminder carries offset_minutes and no '
          'trigger_at_utc.',
        );
      }
      if (offsetMinutes! < 0) {
        throw DomainValidationError('offset_minutes must not be negative.');
      }
    }
  }

  final String id;
  final String? taskId;
  final String? occurrenceId;
  final ReminderTrigger trigger;
  final DateTime? triggerAtUtc;
  final int? offsetMinutes;
  final String channel;
  final ReminderState state;
  final String? platformScheduleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Reminder withState(
    DateTime now, {
    required ReminderState state,
    String? Function()? platformScheduleId,
  }) =>
      Reminder(
        id: id,
        taskId: taskId,
        occurrenceId: occurrenceId,
        trigger: trigger,
        triggerAtUtc: triggerAtUtc,
        offsetMinutes: offsetMinutes,
        channel: channel,
        state: state,
        platformScheduleId: platformScheduleId != null
            ? platformScheduleId()
            : this.platformScheduleId,
        createdAt: createdAt,
        updatedAt: now,
        version: version + 1,
      );
}
