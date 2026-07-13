import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';
import 'task_editor.dart';
import 'undo.dart';

/// Shared focusable task row. Activation (tap, Enter, or Space while
/// focused) toggles completion — the same behavior on every platform.
/// The trailing edit affordance (or long press) opens the task editor;
/// swiping the row away soft-deletes with an Undo snackbar.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.state});

  final TaskDto task;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) {
        final messenger = ScaffoldMessenger.of(context);
        state.deleteTask(task);
        showUndoDeleteSnackBar(messenger, state, task);
      },
      child: Semantics(
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
          trailing: IconButton(
            key: ValueKey('edit-${task.id}'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit task',
            onPressed: () =>
                showTaskEditor(context, state: state, task: task),
          ),
          onTap: () => state.toggleTask(task),
          onLongPress: () =>
              showTaskEditor(context, state: state, task: task),
          // Enter on the focused tile activates onTap via ActivateIntent,
          // which is exactly the Linux "Enter toggles completion" behavior.
        ),
      ),
    );
  }
}
