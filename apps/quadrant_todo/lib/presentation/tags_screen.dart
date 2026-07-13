import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';
import 'tag_tasks_screen.dart';

/// Tag progress view: every active tag with its completed/total bar.
class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: state.tags.isEmpty
              ? const Center(child: Text('No tags yet.'))
              : ListView(
                  children: [
                    for (final tag in state.tags)
                      _TagTile(tag: tag, state: state),
                  ],
                ),
        ),
        _AddTagField(state: state),
      ],
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag, required this.state});

  final TagDto tag;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final fraction = tag.total == 0 ? 0.0 : tag.completed / tag.total;
    return ListTile(
      key: ValueKey('tag-${tag.id}'),
      leading: CircleAvatar(
        radius: 8,
        backgroundColor:
            Color(0xFF000000 | int.parse(tag.color.substring(1), radix: 16)),
      ),
      title: Text(tag.name),
      subtitle: LinearProgressIndicator(value: fraction),
      trailing: Text('${tag.completed}/${tag.total}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TagTasksScreen(tag: tag, state: state),
        ),
      ),
    );
  }
}

class _AddTagField extends StatefulWidget {
  const _AddTagField({required this.state});

  final AppState state;

  @override
  State<_AddTagField> createState() => _AddTagFieldState();
}

class _AddTagFieldState extends State<_AddTagField> {
  final _controller = TextEditingController();

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await widget.state.createTag(name);
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
              key: const ValueKey('add-tag-field'),
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'New tag name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.add),
            tooltip: 'Add tag',
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
