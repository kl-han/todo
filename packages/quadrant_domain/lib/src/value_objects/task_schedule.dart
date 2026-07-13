import '../rules/validation.dart';
import 'plain_date.dart';
import 'schedule_kind.dart';

/// A task's start/due schedule. Immutable and internally consistent by
/// construction: the validating constructor enforces that each side
/// carries exactly the value its kind requires, and that [timezoneId] is
/// present iff a date-time side exists.
///
/// `start` controls when a task becomes actionable or appears on the
/// calendar; `due` is a deadline. Neither changes the Eisenhower quadrant.
class TaskSchedule {
  TaskSchedule({
    this.startKind = ScheduleKind.none,
    this.startDate,
    this.startAtUtc,
    this.dueKind = ScheduleKind.none,
    this.dueDate,
    this.dueAtUtc,
    this.timezoneId,
  }) {
    _validateSide('start', startKind, startDate, startAtUtc);
    _validateSide('due', dueKind, dueDate, dueAtUtc);
    final needsTimezone =
        startKind == ScheduleKind.datetime || dueKind == ScheduleKind.datetime;
    if (needsTimezone && (timezoneId == null || timezoneId!.trim().isEmpty)) {
      throw DomainValidationError(
        'timezone_id is required when a schedule side is datetime.',
      );
    }
    if (!needsTimezone && timezoneId != null) {
      throw DomainValidationError(
        'timezone_id must be absent without a datetime schedule side.',
      );
    }
  }

  const TaskSchedule.none()
      : startKind = ScheduleKind.none,
        startDate = null,
        startAtUtc = null,
        dueKind = ScheduleKind.none,
        dueDate = null,
        dueAtUtc = null,
        timezoneId = null;

  final ScheduleKind startKind;
  final PlainDate? startDate;
  final DateTime? startAtUtc;
  final ScheduleKind dueKind;
  final PlainDate? dueDate;
  final DateTime? dueAtUtc;
  final String? timezoneId;

  bool get isScheduled =>
      startKind != ScheduleKind.none || dueKind != ScheduleKind.none;

  static void _validateSide(
    String side,
    ScheduleKind kind,
    PlainDate? date,
    DateTime? atUtc,
  ) {
    switch (kind) {
      case ScheduleKind.none:
        if (date != null || atUtc != null) {
          throw DomainValidationError(
            '${side}_kind none forbids ${side}_date and ${side}_at_utc.',
          );
        }
      case ScheduleKind.date:
        if (date == null) {
          throw DomainValidationError(
            '${side}_kind date requires ${side}_date.',
          );
        }
        if (atUtc != null) {
          throw DomainValidationError(
            '${side}_kind date forbids ${side}_at_utc.',
          );
        }
      case ScheduleKind.datetime:
        if (atUtc == null) {
          throw DomainValidationError(
            '${side}_kind datetime requires ${side}_at_utc.',
          );
        }
        if (!atUtc.isUtc) {
          throw DomainValidationError(
            '${side}_at_utc must be an absolute UTC instant.',
          );
        }
        if (date != null) {
          throw DomainValidationError(
            '${side}_kind datetime forbids ${side}_date.',
          );
        }
    }
  }
}
