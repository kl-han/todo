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
