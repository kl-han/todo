import 'package:quadrant_domain/quadrant_domain.dart';

import '../errors.dart';
import '../queries/task_query.dart';
import '../repositories.dart';

/// Commands and queries for tasks. All backend routes for tasks terminate
/// here; handlers do HTTP translation only.
class TaskService {
  TaskService(this._tasks, this._tags, {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final TaskRepository _tasks;
  final TagRepository _tags;
  final DateTime Function() _clock;

  List<Task> list(TaskQuery query) => _tasks.query(query);

  List<String> tagIdsOf(String taskId) => _tasks.tagIdsOf(taskId);

  Task create({
    required String title,
    String notes = '',
    bool isUrgent = false,
    bool isImportant = false,
  }) {
    final now = _clock();
    final task = Task(
      id: EntityId.generate(),
      title: validateTaskTitle(title),
      notes: validateTaskNotes(notes),
      isUrgent: isUrgent,
      isImportant: isImportant,
      createdAt: now,
      updatedAt: now,
    );
    _tasks.insert(task);
    return task;
  }

  /// Visible (non-deleted) task or 404.
  Task get(String id) {
    final task = _tasks.findById(id);
    if (task == null || task.isDeleted) {
      throw EntityNotFoundException('No task $id.');
    }
    return task;
  }

  Task update(
    String id, {
    int? expectedVersion,
    String? title,
    String? notes,
    bool? isUrgent,
    bool? isImportant,
    TaskStatus? status,
  }) {
    var task = get(id);
    _checkVersion(task.version, expectedVersion);

    final now = _clock();
    if (title != null || notes != null || isUrgent != null ||
        isImportant != null) {
      task = task.edit(
        now,
        title: title == null ? null : validateTaskTitle(title),
        notes: notes == null ? null : validateTaskNotes(notes),
        isUrgent: isUrgent,
        isImportant: isImportant,
      );
    }
    if (status != null && status != task.status) {
      task = status == TaskStatus.completed
          ? task.complete(now)
          : task.reopen(now);
    }
    _tasks.update(task);
    return task;
  }

  /// Soft delete; the task disappears from queries but remains restorable.
  void softDelete(String id, {int? expectedVersion}) {
    final task = get(id);
    _checkVersion(task.version, expectedVersion);
    _tasks.update(task.softDelete(_clock()));
  }

  /// Restores a recently deleted task. Idempotent: restoring a live task
  /// returns it unchanged.
  Task restore(String id) {
    final task = _tasks.findById(id);
    if (task == null) throw EntityNotFoundException('No task $id.');
    if (!task.isDeleted) return task;
    final restored = task.restore(_clock());
    _tasks.update(restored);
    return restored;
  }

  /// Assigns a tag; bumps the task version. Idempotent.
  Task assignTag(String taskId, String tagId) {
    final task = get(taskId);
    final tag = _tags.findById(tagId);
    if (tag == null || tag.isDeleted) {
      throw EntityNotFoundException('No tag $tagId.');
    }
    if (_tasks.hasTag(taskId, tagId)) return task;
    _tasks.assignTag(taskId, tagId);
    final touched = task.touch(_clock());
    _tasks.update(touched);
    return touched;
  }

  /// Removes a tag; bumps the task version. Idempotent.
  Task removeTag(String taskId, String tagId) {
    final task = get(taskId);
    if (!_tasks.hasTag(taskId, tagId)) return task;
    _tasks.removeTag(taskId, tagId);
    final touched = task.touch(_clock());
    _tasks.update(touched);
    return touched;
  }

  void _checkVersion(int current, int? expected) {
    if (expected != null && expected != current) {
      throw VersionConflictException(currentVersion: current);
    }
  }
}
