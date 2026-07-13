import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'task_tile.dart';

/// Flat task list in matrix order with a status filter.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final tasks = widget.state.tasks.where((task) {
      return switch (_status) {
        'open' => !task.isCompleted,
        'completed' => task.isCompleted,
        _ => true,
      };
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'open', label: Text('Open')),
              ButtonSegment(value: 'completed', label: Text('Completed')),
              ButtonSegment(value: 'all', label: Text('All')),
            ],
            selected: {_status},
            onSelectionChanged: (selection) =>
                setState(() => _status = selection.first),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('Nothing here.'))
              : ListView(
                  children: [
                    for (final task in tasks)
                      TaskTile(task: task, state: widget.state),
                  ],
                ),
        ),
      ],
    );
  }
}
