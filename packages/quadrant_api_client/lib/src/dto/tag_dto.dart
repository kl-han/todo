/// Wire representation of a tag with its progress.
class TagDto {
  const TagDto({
    required this.id,
    required this.name,
    required this.color,
    required this.version,
    required this.completed,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TagDto.fromJson(Map<String, Object?> json) {
    final progress = json['progress'] as Map<String, Object?>;
    return TagDto(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      version: json['version'] as int,
      completed: progress['completed'] as int,
      total: progress['total'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String name;
  final String color;
  final int version;

  /// Completed / total non-deleted tasks carrying this tag.
  final int completed;
  final int total;

  final DateTime createdAt;
  final DateTime updatedAt;
}
