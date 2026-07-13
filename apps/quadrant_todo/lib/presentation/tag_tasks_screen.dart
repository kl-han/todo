import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';
import 'task_tile.dart';

/// Tag task view: the sorted, filtered tasks of one tag.
class TagTasksScreen extends StatefulWidget {
  const TagTasksScreen({super.key, required this.tag, required this.state});

  final TagDto tag;
  final AppState state;

  @override
  State<TagTasksScreen> createState() => _TagTasksScreenState();
}

class _TagTasksScreenState extends State<TagTasksScreen> {
  String _status = 'open';
  late Future<List<TaskDto>> _tasks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _tasks = widget.state.tagTasks(widget.tag.id, status: _status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tag: ${widget.tag.name}')),
      body: Column(
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
              onSelectionChanged: (selection) => setState(() {
                _status = selection.first;
                _load();
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TaskDto>>(
              future: _tasks,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!;
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks with this tag.'));
                }
                return ListView(
                  children: [
                    for (final task in tasks)
                      TaskTile(task: task, state: widget.state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
