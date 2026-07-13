/// Wire representation of a task as served by the v1 API.
class TaskDto {
  const TaskDto({
    required this.id,
    required this.title,
    required this.notes,
    required this.isUrgent,
    required this.isImportant,
    required this.status,
    required this.quadrant,
    required this.version,
    required this.tagIds,
    required this.createdAt,
    required this.updatedAt,
    this.startKind = 'none',
    this.startDate,
    this.startAtUtc,
    this.dueKind = 'none',
    this.dueDate,
    this.dueAtUtc,
    this.timezoneId,
    this.estimatedMinutes,
    this.recurrenceRuleId,
    this.completedAt,
    this.deletedAt,
  });

  factory TaskDto.fromJson(Map<String, Object?> json) => TaskDto(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String,
        isUrgent: json['is_urgent'] as bool,
        isImportant: json['is_important'] as bool,
        status: json['status'] as String,
        quadrant: json['quadrant'] as int,
        version: json['version'] as int,
        tagIds: (json['tag_ids'] as List<Object?>).cast<String>(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        startKind: (json['start_kind'] as String?) ?? 'none',
        startDate: json['start_date'] as String?,
        startAtUtc: json['start_at_utc'] == null
            ? null
            : DateTime.parse(json['start_at_utc'] as String),
        dueKind: (json['due_kind'] as String?) ?? 'none',
        dueDate: json['due_date'] as String?,
        dueAtUtc: json['due_at_utc'] == null
            ? null
            : DateTime.parse(json['due_at_utc'] as String),
        timezoneId: json['timezone_id'] as String?,
        estimatedMinutes: json['estimated_minutes'] as int?,
        recurrenceRuleId: json['recurrence_rule_id'] as String?,
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.parse(json['deleted_at'] as String),
      );

  final String id;
  final String title;
  final String notes;
  final bool isUrgent;
  final bool isImportant;

  /// `open` or `completed`.
  final String status;

  /// Derived quadrant number, 1–4.
  final int quadrant;

  /// `none`, `date`, or `datetime`.
  final String startKind;

  /// Plain `YYYY-MM-DD` task-local date; set iff [startKind] is `date`.
  final String? startDate;

  /// UTC instant; set iff [startKind] is `datetime`.
  final DateTime? startAtUtc;

  /// `none`, `date`, or `datetime`.
  final String dueKind;

  /// Plain `YYYY-MM-DD` task-local date; set iff [dueKind] is `date`.
  final String? dueDate;

  /// UTC instant; set iff [dueKind] is `datetime`.
  final DateTime? dueAtUtc;

  /// IANA timezone of the task's date-time values.
  final String? timezoneId;

  final int? estimatedMinutes;

  /// Read-only; managed through the task's recurrence resource.
  final String? recurrenceRuleId;

  final int version;
  final List<String> tagIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  bool get isCompleted => status == 'completed';
}

/// One quadrant group from the quadrants read model.
class QuadrantGroupDto {
  const QuadrantGroupDto({
    required this.quadrant,
    required this.count,
    required this.tasks,
  });

  factory QuadrantGroupDto.fromJson(Map<String, Object?> json) =>
      QuadrantGroupDto(
        quadrant: json['quadrant'] as int,
        count: json['count'] as int,
        tasks: [
          for (final task in json['tasks'] as List<Object?>)
            TaskDto.fromJson(task as Map<String, Object?>),
        ],
      );

  final int quadrant;
  final int count;
  final List<TaskDto> tasks;
}

/// One entry of one agenda day: which schedule side of which task.
class AgendaEntryDto {
  const AgendaEntryDto({
    required this.kind,
    required this.task,
    this.timeLocal,
  });

  factory AgendaEntryDto.fromJson(Map<String, Object?> json) =>
      AgendaEntryDto(
        kind: json['kind'] as String,
        timeLocal: json['time_local'] as String?,
        task: TaskDto.fromJson(json['task'] as Map<String, Object?>),
      );

  /// `start` or `due`.
  final String kind;

  /// `HH:MM` in the task's timezone; null for all-day entries.
  final String? timeLocal;

  final TaskDto task;
}

/// One task-local calendar date of the agenda read model.
class AgendaDayDto {
  const AgendaDayDto({required this.date, required this.entries});

  factory AgendaDayDto.fromJson(Map<String, Object?> json) => AgendaDayDto(
        date: json['date'] as String,
        entries: [
          for (final entry in json['entries'] as List<Object?>)
            AgendaEntryDto.fromJson(entry as Map<String, Object?>),
        ],
      );

  /// Plain `YYYY-MM-DD` task-local date.
  final String date;

  final List<AgendaEntryDto> entries;
}
