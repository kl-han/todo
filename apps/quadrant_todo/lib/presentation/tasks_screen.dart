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

  /// null = every quadrant.
  int? _quadrant;

  @override
  Widget build(BuildContext context) {
    final tasks = widget.state.tasks.where((task) {
      final statusOk = switch (_status) {
        'open' => !task.isCompleted,
        'completed' => task.isCompleted,
        _ => true,
      };
      return statusOk && (_quadrant == null || task.quadrant == _quadrant);
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
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              key: const ValueKey('quadrant-filter-all'),
              label: const Text('All quadrants'),
              selected: _quadrant == null,
              onSelected: (_) => setState(() => _quadrant = null),
            ),
            for (var q = 1; q <= 4; q++)
              FilterChip(
                key: ValueKey('quadrant-filter-$q'),
                label: Text('Q$q'),
                selected: _quadrant == q,
                onSelected: (_) => setState(() => _quadrant = q),
              ),
          ],
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
