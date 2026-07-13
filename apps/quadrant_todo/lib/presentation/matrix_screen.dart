import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';
import 'task_tile.dart';

const _quadrantTitles = {
  1: 'Urgent · Important',
  2: 'Important',
  3: 'Urgent',
  4: 'Neither',
};

/// The Eisenhower matrix: a 2×2 grid of quadrant panels with counts.
class MatrixScreen extends StatelessWidget {
  const MatrixScreen({super.key, required this.state});

  final AppState state;

  /// Below this width (iPhone portrait) the matrix stacks into a single
  /// scrolling column of quadrant sections; at or above it, the classic
  /// 2×2 grid.
  static const double narrowLayoutBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final groups = state.quadrants;
    if (groups.isEmpty) {
      return const Center(child: Text('No tasks yet — add one below.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < narrowLayoutBreakpoint;
        return Column(
          children: [
            Expanded(
              child: narrow
                  ? ListView(
                      key: const ValueKey('matrix-narrow'),
                      children: [
                        for (final group in groups)
                          _QuadrantSection(group: group, state: state),
                      ],
                    )
                  : Column(
                      key: const ValueKey('matrix-grid'),
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                  child: _QuadrantPanel(
                                      group: groups[0], state: state)),
                              Expanded(
                                  child: _QuadrantPanel(
                                      group: groups[1], state: state)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                  child: _QuadrantPanel(
                                      group: groups[2], state: state)),
                              Expanded(
                                  child: _QuadrantPanel(
                                      group: groups[3], state: state)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            _AddTaskField(state: state),
          ],
        );
      },
    );
  }
}

/// Narrow-layout quadrant: a header plus its tasks inline in one scroll
/// view — no nested scrolling on a phone.
class _QuadrantSection extends StatelessWidget {
  const _QuadrantSection({required this.group, required this.state});

  final QuadrantGroupDto group;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Q${group.quadrant} — ${_quadrantTitles[group.quadrant]} '
            '(${group.count})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (group.tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Empty', style: TextStyle(color: Colors.grey)),
          )
        else
          for (final task in group.tasks) TaskTile(task: task, state: state),
        const Divider(),
      ],
    );
  }
}

class _QuadrantPanel extends StatelessWidget {
  const _QuadrantPanel({required this.group, required this.state});

  final QuadrantGroupDto group;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('quadrant-${group.quadrant}'),
      margin: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              'Q${group.quadrant} — ${_quadrantTitles[group.quadrant]} '
              '(${group.count})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: group.tasks.isEmpty
                ? const Center(
                    child: Text('Empty', style: TextStyle(color: Colors.grey)),
                  )
                : ListView(
                    children: [
                      for (final task in group.tasks)
                        TaskTile(task: task, state: state),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskField extends StatefulWidget {
  const _AddTaskField({required this.state});

  final AppState state;

  @override
  State<_AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<_AddTaskField> {
  final _controller = TextEditingController();
  bool _urgent = false;
  bool _important = false;

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await widget.state.addTask(
      title,
      isUrgent: _urgent,
      isImportant: _important,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('add-task-field'),
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'New task title',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('urgent'),
            selected: _urgent,
            onSelected: (value) => setState(() => _urgent = value),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('important'),
            selected: _important,
            onSelected: (value) => setState(() => _important = value),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('add-task-button'),
            icon: const Icon(Icons.add),
            tooltip: 'Add task',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
