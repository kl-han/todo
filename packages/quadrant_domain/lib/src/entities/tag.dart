/// A tag. Immutable; mutations increment [version] like tasks.
class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  final String id;
  final String name;

  /// `#RRGGBB` hex color.
  final String color;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  bool get isDeleted => deletedAt != null;

  Tag edit(DateTime now, {String? name, String? color}) => Tag(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt,
        updatedAt: now,
        deletedAt: deletedAt,
        version: version + 1,
      );

  Tag softDelete(DateTime now) => Tag(
        id: id,
        name: name,
        color: color,
        createdAt: createdAt,
        updatedAt: now,
        deletedAt: now,
        version: version + 1,
      );
}

/// Completed/total progress of the non-deleted tasks carrying a tag.
class TagProgress {
  const TagProgress({required this.completed, required this.total});

  final int completed;
  final int total;
}
