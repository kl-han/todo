/// Wire representation of a recurrence rule.
class RecurrenceDto {
  const RecurrenceDto({
    required this.id,
    required this.taskId,
    required this.dtstart,
    required this.rrule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurrenceDto.fromJson(Map<String, Object?> json) => RecurrenceDto(
        id: json['id'] as String,
        taskId: json['task_id'] as String,
        dtstart: json['dtstart'] as String,
        rrule: json['rrule'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  final String id;
  final String taskId;

  /// Plain `YYYY-MM-DD` anchor date.
  final String dtstart;

  /// Canonical RFC 5545 RRULE subset.
  final String rrule;

  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Wire representation of one materialized occurrence.
class OccurrenceDto {
  const OccurrenceDto({
    required this.id,
    required this.taskId,
    required this.recurrenceRuleId,
    required this.originalDate,
    required this.kind,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.occurrenceDate,
    this.occurrenceAtUtc,
    this.completedAt,
  });

  factory OccurrenceDto.fromJson(Map<String, Object?> json) => OccurrenceDto(
        id: json['id'] as String,
        taskId: json['task_id'] as String,
        recurrenceRuleId: json['recurrence_rule_id'] as String,
        originalDate: json['original_date'] as String,
        kind: json['kind'] as String,
        status: json['status'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        occurrenceDate: json['occurrence_date'] as String?,
        occurrenceAtUtc: json['occurrence_at_utc'] == null
            ? null
            : DateTime.parse(json['occurrence_at_utc'] as String),
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
      );

  final String id;
  final String taskId;
  final String recurrenceRuleId;

  /// The generated date — the occurrence's permanent identity.
  final String originalDate;

  /// `start` or `due`.
  final String kind;

  /// Plain `YYYY-MM-DD`; set for date-kind occurrences.
  final String? occurrenceDate;

  /// UTC instant; set for datetime-kind occurrences.
  final DateTime? occurrenceAtUtc;

  /// `open`, `completed`, or `skipped`.
  final String status;

  final DateTime? completedAt;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Wire representation of a reminder.
class ReminderDto {
  const ReminderDto({
    required this.id,
    required this.triggerType,
    required this.channel,
    required this.state,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.occurrenceId,
    this.triggerAtUtc,
    this.offsetMinutes,
    this.effectiveTriggerAtUtc,
    this.platformScheduleId,
  });

  factory ReminderDto.fromJson(Map<String, Object?> json) => ReminderDto(
        id: json['id'] as String,
        triggerType: json['trigger_type'] as String,
        channel: json['channel'] as String,
        state: json['state'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        taskId: json['task_id'] as String?,
        occurrenceId: json['occurrence_id'] as String?,
        triggerAtUtc: json['trigger_at_utc'] == null
            ? null
            : DateTime.parse(json['trigger_at_utc'] as String),
        offsetMinutes: json['offset_minutes'] as int?,
        effectiveTriggerAtUtc: json['effective_trigger_at_utc'] == null
            ? null
            : DateTime.parse(json['effective_trigger_at_utc'] as String),
        platformScheduleId: json['platform_schedule_id'] as String?,
      );

  final String id;
  final String? taskId;
  final String? occurrenceId;

  /// `absolute`, `relative_start`, or `relative_due`.
  final String triggerType;

  final DateTime? triggerAtUtc;
  final int? offsetMinutes;

  /// Recomputed from the current task/occurrence schedule on every read;
  /// null when the referenced side no longer exists.
  final DateTime? effectiveTriggerAtUtc;

  final String channel;

  /// `pending`, `scheduled`, `delivered`, or `dismissed`.
  final String state;

  final String? platformScheduleId;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
}
