/// Wire representation of a daily plan.
class DailyPlanDto {
  const DailyPlanDto({
    required this.id,
    required this.localDate,
    required this.plannedMinutes,
    required this.reviewNotes,
    required this.status,
    required this.items,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyPlanDto.fromJson(Map<String, Object?> json) => DailyPlanDto(
        id: json['id'] as String,
        localDate: json['local_date'] as String,
        plannedMinutes: json['planned_minutes'] as int,
        reviewNotes: json['review_notes'] as String,
        status: json['status'] as String,
        items: [
          for (final item in json['items'] as List<Object?>)
            PlanItemDto.fromJson(item as Map<String, Object?>),
        ],
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  final String id;

  /// Plain `YYYY-MM-DD`.
  final String localDate;

  /// Derived sum of the items' planned minutes.
  final int plannedMinutes;

  final String reviewNotes;

  /// `open` or `reviewed`.
  final String status;

  final List<PlanItemDto> items;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// One planned task/occurrence within a day.
class PlanItemDto {
  const PlanItemDto({
    required this.id,
    required this.dailyPlanId,
    required this.position,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.occurrenceId,
    this.plannedMinutes,
    this.scheduledStart,
    this.outcome,
  });

  factory PlanItemDto.fromJson(Map<String, Object?> json) => PlanItemDto(
        id: json['id'] as String,
        dailyPlanId: json['daily_plan_id'] as String,
        position: json['position'] as int,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        taskId: json['task_id'] as String?,
        occurrenceId: json['occurrence_id'] as String?,
        plannedMinutes: json['planned_minutes'] as int?,
        scheduledStart: json['scheduled_start'] as String?,
        outcome: json['outcome'] as String?,
      );

  final String id;
  final String dailyPlanId;
  final String? taskId;
  final String? occurrenceId;
  final int position;
  final int? plannedMinutes;

  /// `HH:MM` wall-clock start within the plan day.
  final String? scheduledStart;

  /// `done`, `partial`, `skipped`, or `moved`; null while undecided.
  final String? outcome;

  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
}
