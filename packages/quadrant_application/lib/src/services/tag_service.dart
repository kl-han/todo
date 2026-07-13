import 'package:quadrant_domain/quadrant_domain.dart';

import '../errors.dart';
import '../queries/task_query.dart';
import '../repositories.dart';

/// A tag together with its live progress, as listed by the tag views.
class TagWithProgress {
  const TagWithProgress(this.tag, this.progress);

  final Tag tag;
  final TagProgress progress;
}

/// Commands and queries for tags.
class TagService {
  TagService(this._tags, this._tasks, {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final TagRepository _tags;
  final TaskRepository _tasks;
  final DateTime Function() _clock;

  List<TagWithProgress> listWithProgress() => [
        for (final tag in _tags.listActive())
          TagWithProgress(tag, _tags.progressOf(tag.id)),
      ];

  Tag create({required String name, String color = '#808080'}) {
    final validName = validateTagName(name);
    _ensureNameFree(validName);
    final now = _clock();
    final tag = Tag(
      id: EntityId.generate(),
      name: validName,
      color: validateTagColor(color),
      createdAt: now,
      updatedAt: now,
    );
    _tags.insert(tag);
    return tag;
  }

  Tag get(String id) {
    final tag = _tags.findById(id);
    if (tag == null || tag.isDeleted) {
      throw EntityNotFoundException('No tag $id.');
    }
    return tag;
  }

  TagProgress progressOf(String id) => _tags.progressOf(get(id).id);

  Tag update(String id, {int? expectedVersion, String? name, String? color}) {
    final tag = get(id);
    if (expectedVersion != null && expectedVersion != tag.version) {
      throw VersionConflictException(currentVersion: tag.version);
    }
    String? validName;
    if (name != null) {
      validName = validateTagName(name);
      if (validName != tag.name) _ensureNameFree(validName);
    }
    final updated = tag.edit(
      _clock(),
      name: validName,
      color: color == null ? null : validateTagColor(color),
    );
    _tags.update(updated);
    return updated;
  }

  void softDelete(String id, {int? expectedVersion}) {
    final tag = get(id);
    if (expectedVersion != null && expectedVersion != tag.version) {
      throw VersionConflictException(currentVersion: tag.version);
    }
    _tags.update(tag.softDelete(_clock()));
  }

  /// Sorted, filtered tasks carrying the tag.
  List<Task> tasksOf(
    String id, {
    StatusFilter status = StatusFilter.open,
  }) {
    get(id); // 404 for unknown tags
    return _tasks.query(TaskQuery(status: status, tagId: id));
  }

  void _ensureNameFree(String name) {
    if (_tags.findActiveByName(name) != null) {
      throw StateConflictException('A tag named "$name" already exists.');
    }
  }
}
