import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';
import 'task_tile.dart';

/// Flat or grouped task list in matrix order with a status filter.
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

  TaskGrouping _grouping = TaskGrouping.none;

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SegmentedButton<TaskGrouping>(
            key: const ValueKey('grouping-selector'),
            segments: const [
              ButtonSegment(value: TaskGrouping.none, label: Text('None')),
              ButtonSegment(value: TaskGrouping.tag, label: Text('Tag')),
              ButtonSegment(value: TaskGrouping.flags, label: Text('Flags')),
              ButtonSegment(value: TaskGrouping.tagAndFlags, label: Text('Both')),
            ],
            selected: {_grouping},
            onSelectionChanged: (selection) =>
                setState(() => _grouping = selection.first),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('Nothing here.'))
              : _grouping == TaskGrouping.none
                  ? ListView(
                      children: [
                        for (final task in tasks)
                          TaskTile(task: task, state: widget.state),
                      ],
                    )
                  : _grouped(groupTasks(
                      tasks,
                      grouping: _grouping,
                      tags: widget.state.tags,
                    )),
        ),
      ],
    );
  }

  Widget _grouped(List<TaskGroup> groups) {
    final children = <Widget>[];
    for (final group in groups) {
      children.add(_header(group));
      if (group.subgroups.isNotEmpty) {
        for (final subgroup in group.subgroups) {
          children.add(_subHeader(subgroup));
          for (final task in subgroup.tasks) {
            children.add(TaskTile(task: task, state: widget.state));
          }
        }
      } else {
        for (final task in group.tasks) {
          children.add(TaskTile(task: task, state: widget.state));
        }
      }
    }
    return ListView(children: children);
  }

  Widget _header(TaskGroup group) {
    final tag = group.tag;
    return Padding(
      key: ValueKey('group-${group.key}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(group.label, style: Theme.of(context).textTheme.titleSmall),
          if (tag != null) Text('${tag.completed}/${tag.total}'),
        ],
      ),
    );
  }

  Widget _subHeader(TaskGroup subgroup) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 16, 2),
        child: Text(
          subgroup.label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
}
