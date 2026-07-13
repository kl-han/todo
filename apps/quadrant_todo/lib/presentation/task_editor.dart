import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';

/// Opens the modal task editor. Fits iPhone-sized screens as a full-width
/// bottom sheet and desktop as a constrained dialog-like sheet.
Future<void> showTaskEditor(
  BuildContext context, {
  required AppState state,
  required TaskDto task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TaskEditorSheet(state: state, task: task),
  );
}

/// Edit title, notes, classification, and tags; delete lives here too.
class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, required this.state, required this.task});

  final AppState state;
  final TaskDto task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task.title);
  late final TextEditingController _notes =
      TextEditingController(text: widget.task.notes);
  late bool _urgent = widget.task.isUrgent;
  late bool _important = widget.task.isImportant;
  late final Set<String> _tagIds = {...widget.task.tagIds};

  Future<void> _save() async {
    final task = widget.task;
    await widget.state.updateTask(
      task,
      title: _title.text,
      notes: _notes.text,
      isUrgent: _urgent,
      isImportant: _important,
    );
    // Tag membership changes are separate idempotent calls.
    for (final tagId in _tagIds.difference(task.tagIds.toSet())) {
      await widget.state.assignTag(task, tagId);
    }
    for (final tagId in task.tagIds.toSet().difference(_tagIds)) {
      await widget.state.removeTag(task, tagId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.state.deleteTask(widget.task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: const ValueKey('task-editor'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('editor-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('editor-notes'),
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 4,
            ),
            SwitchListTile(
              key: const ValueKey('editor-urgent'),
              title: const Text('Urgent'),
              value: _urgent,
              onChanged: (value) => setState(() => _urgent = value),
            ),
            SwitchListTile(
              key: const ValueKey('editor-important'),
              title: const Text('Important'),
              value: _important,
              onChanged: (value) => setState(() => _important = value),
            ),
            if (widget.state.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in widget.state.tags)
                    FilterChip(
                      key: ValueKey('editor-tag-${tag.id}'),
                      label: Text(tag.name),
                      selected: _tagIds.contains(tag.id),
                      onSelected: (selected) => setState(() {
                        selected ? _tagIds.add(tag.id) : _tagIds.remove(tag.id);
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  key: const ValueKey('editor-delete'),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('editor-save'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }
}
