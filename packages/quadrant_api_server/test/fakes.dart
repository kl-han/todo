import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';

/// In-memory repositories for handler tests. HTTP semantics are exercised
/// here; storage semantics are covered by quadrant_store's own tests and
/// the conformance suite against real backends.
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};
  final Set<(String, String)> _links = {};

  @override
  Task? findById(String id) => _tasks[id];

  @override
  List<Task> query(TaskQuery query) {
    final result = _tasks.values.where((task) {
      if (task.isDeleted) return false;
      final statusOk = switch (query.status) {
        StatusFilter.open => task.status == TaskStatus.open,
        StatusFilter.completed => task.status == TaskStatus.completed,
        StatusFilter.all => true,
      };
      if (!statusOk) return false;
      if (query.quadrant != null && task.quadrant != query.quadrant) {
        return false;
      }
      if (query.tagId != null && !_links.contains((task.id, query.tagId!))) {
        return false;
      }
      return true;
    }).toList()
      ..sort(_matrixModifiedAsc);
    return result;
  }

  static int _matrixModifiedAsc(Task a, Task b) {
    int flag(bool v) => v ? 0 : 1;
    final urgent = flag(a.isUrgent).compareTo(flag(b.isUrgent));
    if (urgent != 0) return urgent;
    final important = flag(a.isImportant).compareTo(flag(b.isImportant));
    if (important != 0) return important;
    final updated = a.updatedAt.compareTo(b.updatedAt);
    if (updated != 0) return updated;
    return a.id.compareTo(b.id);
  }

  @override
  void insert(Task task) => _tasks[task.id] = task;

  @override
  void update(Task task) => _tasks[task.id] = task;

  @override
  List<String> tagIdsOf(String taskId) => [
        for (final (task, tag) in _links)
          if (task == taskId) tag,
      ]..sort();

  @override
  bool hasTag(String taskId, String tagId) =>
      _links.contains((taskId, tagId));

  @override
  void assignTag(String taskId, String tagId) => _links.add((taskId, tagId));

  @override
  void removeTag(String taskId, String tagId) =>
      _links.remove((taskId, tagId));
}

class InMemoryTagRepository implements TagRepository {
  InMemoryTagRepository(this._taskRepository);

  final InMemoryTaskRepository _taskRepository;
  final Map<String, Tag> _tags = {};

  @override
  Tag? findById(String id) => _tags[id];

  @override
  Tag? findActiveByName(String name) {
    for (final tag in _tags.values) {
      if (!tag.isDeleted && tag.name == name) return tag;
    }
    return null;
  }

  @override
  List<Tag> listActive() =>
      (_tags.values.where((t) => !t.isDeleted).toList())
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  TagProgress progressOf(String tagId) {
    var total = 0;
    var completed = 0;
    for (final (taskId, tag) in _taskRepository._links) {
      if (tag != tagId) continue;
      final task = _taskRepository.findById(taskId);
      if (task == null || task.isDeleted) continue;
      total += 1;
      if (task.status == TaskStatus.completed) completed += 1;
    }
    return TagProgress(completed: completed, total: total);
  }

  @override
  void insert(Tag tag) => _tags[tag.id] = tag;

  @override
  void update(Tag tag) => _tags[tag.id] = tag;
}

/// One in-memory vault named `default`, plus a resolver for it.
AppServices inMemoryServices() {
  final taskRepo = InMemoryTaskRepository();
  return AppServices(
    taskRepository: taskRepo,
    tagRepository: InMemoryTagRepository(taskRepo),
  );
}
