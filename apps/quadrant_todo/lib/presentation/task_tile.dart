import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';

/// Shared focusable task row. Activation (tap, Enter, or Space while
/// focused) toggles completion — the same behavior on every platform.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.state});

  final TaskDto task;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${task.title}, '
          '${task.isCompleted ? 'completed' : 'open'}, quadrant '
          '${task.quadrant}',
      child: ListTile(
        key: ValueKey('task-${task.id}'),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => state.toggleTask(task),
        ),
        title: Text(
          task.title,
          style: task.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: task.notes.isEmpty ? null : Text(task.notes, maxLines: 1),
        onTap: () => state.toggleTask(task),
        // Enter on the focused tile activates onTap via ActivateIntent,
        // which is exactly the Linux "Enter toggles completion" behavior.
      ),
    );
  }
}
