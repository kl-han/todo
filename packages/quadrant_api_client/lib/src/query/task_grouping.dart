import '../dto/tag_dto.dart';
import '../dto/task_dto.dart';

/// How the Tasks view groups the flat, matrix-ordered task list. Grouping is
/// presentation over the same result set (see
/// `docs/src/product/sorting-filtering.rst`): it never reorders within a
/// group and composes with any status filter or filter rule applied upstream.
enum TaskGrouping {
  /// No grouping; a single group holding the flat list.
  none,

  /// One group per tag the tasks carry, plus an untagged group.
  tag,

  /// One group per importance/urgency combination.
  flags,

  /// Tag groups subdivided by importance/urgency.
  tagAndFlags,
}

/// One rendered group. [tasks] preserves the input (matrix) order. [tag] is
/// set for tag groups and carries the tag's progress; [quadrant] (1–4) is set
/// for flag groups; [subgroups] holds the flag split for [TaskGrouping.tagAndFlags].
class TaskGroup {
  const TaskGroup({
    required this.key,
    required this.label,
    required this.tasks,
    this.tag,
    this.quadrant,
    this.subgroups = const [],
  });

  /// Stable identity for widget keys and selection.
  final String key;

  /// Human-readable heading.
  final String label;

  final List<TaskDto> tasks;
  final TagDto? tag;
  final int? quadrant;
  final List<TaskGroup> subgroups;
}

/// Fixed importance/urgency buckets in the matrix priority order the flat
/// list already uses (urgent first, then important): Q1, Q3, Q2, Q4.
const List<({int quadrant, String label})> _flagBuckets = [
  (quadrant: 1, label: 'Urgent & Important'),
  (quadrant: 3, label: 'Urgent, Not Important'),
  (quadrant: 2, label: 'Important, Not Urgent'),
  (quadrant: 4, label: 'Neither'),
];

/// Groups [tasks] for presentation. [tasks] must already be in the API's
/// matrix order; grouping preserves it inside every group. [tags] supplies
/// tag names and progress for tag-based groupings.
List<TaskGroup> groupTasks(
  List<TaskDto> tasks, {
  required TaskGrouping grouping,
  List<TagDto> tags = const [],
}) {
  switch (grouping) {
    case TaskGrouping.none:
      return [TaskGroup(key: 'all', label: 'All', tasks: List.of(tasks))];
    case TaskGrouping.flags:
      return _byFlags(tasks);
    case TaskGrouping.tag:
      return _byTag(tasks, tags);
    case TaskGrouping.tagAndFlags:
      return [
        for (final group in _byTag(tasks, tags))
          TaskGroup(
            key: group.key,
            label: group.label,
            tasks: group.tasks,
            tag: group.tag,
            subgroups: _byFlags(group.tasks),
          ),
      ];
  }
}

List<TaskGroup> _byFlags(List<TaskDto> tasks) {
  final groups = <TaskGroup>[];
  for (final bucket in _flagBuckets) {
    final members = [
      for (final task in tasks)
        if (task.quadrant == bucket.quadrant) task,
    ];
    if (members.isEmpty) continue;
    groups.add(TaskGroup(
      key: 'q${bucket.quadrant}',
      label: bucket.label,
      tasks: members,
      quadrant: bucket.quadrant,
    ));
  }
  return groups;
}

List<TaskGroup> _byTag(List<TaskDto> tasks, List<TagDto> tags) {
  final byId = {for (final tag in tags) tag.id: tag};

  // Tag ids present in the current list, ordered by tag name (then id) so the
  // grouping is deterministic and matches the name-ordered tag list.
  final present = <String>{
    for (final task in tasks)
      for (final tagId in task.tagIds)
        if (byId.containsKey(tagId)) tagId,
  }.toList()
    ..sort((a, b) {
      final byName = byId[a]!.name.compareTo(byId[b]!.name);
      return byName != 0 ? byName : a.compareTo(b);
    });

  final groups = <TaskGroup>[
    for (final tagId in present)
      TaskGroup(
        key: 'tag:$tagId',
        label: byId[tagId]!.name,
        tag: byId[tagId],
        tasks: [
          for (final task in tasks)
            if (task.tagIds.contains(tagId)) task,
        ],
      ),
  ];

  final untagged = [
    for (final task in tasks)
      if (task.tagIds.every((id) => !byId.containsKey(id))) task,
  ];
  if (untagged.isNotEmpty) {
    groups.add(TaskGroup(key: 'untagged', label: 'Untagged', tasks: untagged));
  }
  return groups;
}
