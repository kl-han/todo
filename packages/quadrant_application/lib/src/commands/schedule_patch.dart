import 'package:quadrant_domain/quadrant_domain.dart';

/// Partial schedule update, merged over a task's existing schedule.
///
/// Merge rule (normative in `api/openapi.yaml`, TaskPatch): providing a
/// side's kind resets that side to exactly the values provided with it;
/// providing a value without its kind updates the value under the
/// existing kind. The merged result must satisfy [TaskSchedule]'s
/// invariants, so a kind change without its required value fails as a
/// validation problem rather than keeping a stale value.
class SchedulePatch {
  const SchedulePatch({
    this.startKind,
    this.startDate,
    this.startAtUtc,
    this.dueKind,
    this.dueDate,
    this.dueAtUtc,
    this.timezoneId,
  });

  final ScheduleKind? startKind;
  final PlainDate? startDate;
  final DateTime? startAtUtc;
  final ScheduleKind? dueKind;
  final PlainDate? dueDate;
  final DateTime? dueAtUtc;
  final String? timezoneId;

  bool get isEmpty =>
      startKind == null &&
      startDate == null &&
      startAtUtc == null &&
      dueKind == null &&
      dueDate == null &&
      dueAtUtc == null &&
      timezoneId == null;

  /// The patched schedule. Throws [DomainValidationError] when the merged
  /// result is inconsistent.
  TaskSchedule applyTo(TaskSchedule existing) {
    final newStartKind = startKind ?? existing.startKind;
    final newDueKind = dueKind ?? existing.dueKind;
    final timezone = timezoneId ?? existing.timezoneId;
    final needsTimezone = newStartKind == ScheduleKind.datetime ||
        newDueKind == ScheduleKind.datetime;
    if (timezoneId != null && !needsTimezone) {
      throw DomainValidationError(
        'timezone_id requires a datetime schedule side.',
      );
    }
    return TaskSchedule(
      startKind: newStartKind,
      startDate:
          startKind != null ? startDate : (startDate ?? existing.startDate),
      startAtUtc:
          startKind != null ? startAtUtc : (startAtUtc ?? existing.startAtUtc),
      dueKind: newDueKind,
      dueDate: dueKind != null ? dueDate : (dueDate ?? existing.dueDate),
      dueAtUtc: dueKind != null ? dueAtUtc : (dueAtUtc ?? existing.dueAtUtc),
      // A schedule that loses its last datetime side sheds an inherited
      // timezone instead of failing validation; an explicitly provided
      // timezone without a datetime side was rejected above.
      timezoneId: needsTimezone ? timezone : null,
    );
  }
}
