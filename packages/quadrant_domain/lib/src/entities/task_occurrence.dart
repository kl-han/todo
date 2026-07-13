import '../rules/validation.dart';
import '../value_objects/plain_date.dart';
import '../value_objects/schedule_kind.dart';

/// Occurrence lifecycle. Completing one occurrence never resets or touches
/// its siblings — history is per occurrence, never rewritten.
enum OccurrenceStatus {
  open,
  completed,
  skipped;

  String get wireName => name;

  static OccurrenceStatus fromWire(String value) => switch (value) {
        'open' => open,
        'completed' => completed,
        'skipped' => skipped,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown occurrence status'),
      };
}

/// Which schedule side an occurrence repeats.
enum OccurrenceKind {
  start,
  due;

  String get wireName => name;

  static OccurrenceKind fromWire(String value) => switch (value) {
        'start' => start,
        'due' => due,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown occurrence kind'),
      };
}

/// One materialized occurrence of a recurring task. [originalDate] is the
/// generated date and the occurrence's permanent identity; rescheduling
/// moves [date]/[atUtc] but never [originalDate].
class TaskOccurrence {
  TaskOccurrence({
    required this.id,
    required this.taskId,
    required this.recurrenceRuleId,
    required this.originalDate,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.date,
    this.atUtc,
    this.status = OccurrenceStatus.open,
    this.completedAt,
    this.version = 1,
  }) {
    if ((date == null) == (atUtc == null)) {
      throw DomainValidationError(
        'An occurrence carries exactly one of occurrence_date and '
        'occurrence_at_utc.',
      );
    }
    if (atUtc != null && !atUtc!.isUtc) {
      throw DomainValidationError(
        'occurrence_at_utc must be an absolute UTC instant.',
      );
    }
  }

  final String id;
  final String taskId;
  final String recurrenceRuleId;
  final PlainDate originalDate;
  final OccurrenceKind kind;
  final PlainDate? date;
  final DateTime? atUtc;
  final OccurrenceStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  /// The shape of the side this occurrence repeats.
  ScheduleKind get scheduleKind =>
      date != null ? ScheduleKind.date : ScheduleKind.datetime;

  TaskOccurrence _next(
    DateTime now, {
    PlainDate? date,
    DateTime? atUtc,
    OccurrenceStatus? status,
    DateTime? Function()? completedAt,
  }) =>
      TaskOccurrence(
        id: id,
        taskId: taskId,
        recurrenceRuleId: recurrenceRuleId,
        originalDate: originalDate,
        kind: kind,
        date: date ?? this.date,
        atUtc: atUtc ?? this.atUtc,
        status: status ?? this.status,
        completedAt: completedAt != null ? completedAt() : this.completedAt,
        createdAt: createdAt,
        updatedAt: now,
        version: version + 1,
      );

  TaskOccurrence complete(DateTime now) => _next(now,
      status: OccurrenceStatus.completed, completedAt: () => now);

  TaskOccurrence skip(DateTime now) => _next(now,
      status: OccurrenceStatus.skipped, completedAt: () => null);

  TaskOccurrence reopen(DateTime now) =>
      _next(now, status: OccurrenceStatus.open, completedAt: () => null);

  /// Moves a date-kind occurrence; [originalDate] stays put.
  TaskOccurrence rescheduleDate(DateTime now, PlainDate newDate) {
    if (scheduleKind != ScheduleKind.date) {
      throw DomainValidationError(
        'occurrence_date applies only to date-kind occurrences.',
      );
    }
    return _next(now, date: newDate);
  }

  /// Moves a datetime-kind occurrence; [originalDate] stays put.
  TaskOccurrence rescheduleInstant(DateTime now, DateTime newAtUtc) {
    if (scheduleKind != ScheduleKind.datetime) {
      throw DomainValidationError(
        'occurrence_at_utc applies only to datetime-kind occurrences.',
      );
    }
    if (!newAtUtc.isUtc) {
      throw DomainValidationError(
        'occurrence_at_utc must be an absolute UTC instant.',
      );
    }
    return _next(now, atUtc: newAtUtc);
  }
}
