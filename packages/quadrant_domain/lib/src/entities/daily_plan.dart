import '../rules/validation.dart';
import '../value_objects/plain_date.dart';

/// Whether the day has been reviewed.
enum PlanStatus {
  open,
  reviewed;

  String get wireName => name;

  static PlanStatus fromWire(String value) => switch (value) {
        'open' => open,
        'reviewed' => reviewed,
        _ => throw ArgumentError.value(value, 'value', 'unknown plan status'),
      };
}

/// What happened to one planned item by the end of the day.
enum PlanOutcome {
  done,
  partial,
  skipped,
  moved;

  String get wireName => name;

  static PlanOutcome fromWire(String value) => switch (value) {
        'done' => done,
        'partial' => partial,
        'skipped' => skipped,
        'moved' => moved,
        _ => throw ArgumentError.value(value, 'value', 'unknown outcome'),
      };
}

final RegExp _timePattern = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$');

String validateWallTime(String value) {
  if (!_timePattern.hasMatch(value)) {
    throw DomainValidationError('scheduled_start must be HH:MM.');
  }
  return value;
}

/// One day's plan: a per-date singleton the user fills deliberately —
/// nothing is auto-filled with due tasks.
class DailyPlan {
  const DailyPlan({
    required this.id,
    required this.localDate,
    required this.createdAt,
    required this.updatedAt,
    this.reviewNotes = '',
    this.status = PlanStatus.open,
    this.version = 1,
  });

  final String id;
  final PlainDate localDate;
  final String reviewNotes;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  DailyPlan review(DateTime now, {String? reviewNotes, PlanStatus? status}) =>
      DailyPlan(
        id: id,
        localDate: localDate,
        reviewNotes: reviewNotes == null
            ? this.reviewNotes
            : validateTaskNotes(reviewNotes),
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: now,
        version: version + 1,
      );
}

/// One task or occurrence placed into a day, with an optional time block
/// and, at day's end, an outcome.
class DailyPlanItem {
  DailyPlanItem({
    required this.id,
    required this.dailyPlanId,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.occurrenceId,
    this.plannedMinutes,
    this.scheduledStart,
    this.outcome,
    this.version = 1,
  }) {
    if ((taskId == null) == (occurrenceId == null)) {
      throw DomainValidationError(
        'A plan item references exactly one of task_id and occurrence_id.',
      );
    }
    if (plannedMinutes != null) validateEstimatedMinutes(plannedMinutes!);
    if (scheduledStart != null) validateWallTime(scheduledStart!);
  }

  final String id;
  final String dailyPlanId;
  final String? taskId;
  final String? occurrenceId;
  final int position;
  final int? plannedMinutes;

  /// `HH:MM` wall-clock start within the plan day.
  final String? scheduledStart;

  final PlanOutcome? outcome;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  /// Nullable-override pattern for the clearable fields.
  DailyPlanItem update(
    DateTime now, {
    int? position,
    int? Function()? plannedMinutes,
    String? Function()? scheduledStart,
    PlanOutcome? Function()? outcome,
  }) =>
      DailyPlanItem(
        id: id,
        dailyPlanId: dailyPlanId,
        taskId: taskId,
        occurrenceId: occurrenceId,
        position: position ?? this.position,
        plannedMinutes:
            plannedMinutes != null ? plannedMinutes() : this.plannedMinutes,
        scheduledStart:
            scheduledStart != null ? scheduledStart() : this.scheduledStart,
        outcome: outcome != null ? outcome() : this.outcome,
        createdAt: createdAt,
        updatedAt: now,
        version: version + 1,
      );
}
