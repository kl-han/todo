import '../repositories.dart';
import 'quadrant_service.dart';
import 'tag_service.dart';
import 'task_service.dart';

/// The full application service set for one vault. Backends construct one
/// per vault and hand it to the REST routing layer.
class AppServices {
  AppServices({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
    DateTime Function()? clock,
  })  : tasks = TaskService(taskRepository, tagRepository, clock: clock),
        tags = TagService(tagRepository, taskRepository, clock: clock),
        quadrants = QuadrantService(taskRepository);

  final TaskService tasks;
  final TagService tags;
  final QuadrantService quadrants;
}
