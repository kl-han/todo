import 'package:quadrant_domain/quadrant_domain.dart';

import '../queries/task_query.dart';
import '../repositories.dart';

/// One quadrant's tasks and count in the grouped read model.
class QuadrantGroup {
  const QuadrantGroup(this.quadrant, this.tasks);

  final Quadrant quadrant;
  final List<Task> tasks;

  int get count => tasks.length;
}

/// Read model for the matrix screen: all four quadrants in one query.
class QuadrantService {
  QuadrantService(this._tasks);

  final TaskRepository _tasks;

  List<QuadrantGroup> grouped({StatusFilter status = StatusFilter.open}) {
    final all = _tasks.query(TaskQuery(status: status));
    return [
      for (final quadrant in Quadrant.values)
        QuadrantGroup(
          quadrant,
          [for (final task in all) if (task.quadrant == quadrant) task],
        ),
    ];
  }
}
