import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:test/test.dart';

final _epoch = DateTime.utc(2026);

int _quadrant(bool urgent, bool important) {
  if (urgent && important) return 1;
  if (important) return 2;
  if (urgent) return 3;
  return 4;
}

TaskDto _task(
  String id, {
  bool urgent = false,
  bool important = false,
  List<String> tags = const [],
}) =>
    TaskDto(
      id: id,
      title: id,
      notes: '',
      isUrgent: urgent,
      isImportant: important,
      status: 'open',
      quadrant: _quadrant(urgent, important),
      version: 1,
      tagIds: tags,
      createdAt: _epoch,
      updatedAt: _epoch,
    );

TagDto _tag(String id, String name) => TagDto(
      id: id,
      name: name,
      color: '#112233',
      version: 1,
      completed: 0,
      total: 0,
      createdAt: _epoch,
      updatedAt: _epoch,
    );

List<String> _ids(TaskGroup group) => [for (final t in group.tasks) t.id];

void main() {
  group('groupTasks', () {
    test('none yields a single group with the flat list', () {
      final tasks = [_task('a'), _task('b')];
      final groups = groupTasks(tasks, grouping: TaskGrouping.none);
      expect(groups, hasLength(1));
      expect(_ids(groups.single), ['a', 'b']);
    });

    test('flags groups in matrix priority order, empties omitted', () {
      final tasks = [
        _task('q1', urgent: true, important: true),
        _task('q3', urgent: true),
        _task('q4a'),
        _task('q4b'),
      ];
      final groups = groupTasks(tasks, grouping: TaskGrouping.flags);
      // Q2 is empty and omitted; order follows Q1, Q3, Q2, Q4.
      expect(groups.map((g) => g.quadrant), [1, 3, 4]);
      expect(_ids(groups[2]), ['q4a', 'q4b'],
          reason: 'within-group order is preserved');
    });

    test('tag groups: multi-tag membership, name order, untagged last', () {
      final tags = [_tag('t-work', 'work'), _tag('t-home', 'home')];
      final tasks = [
        _task('both', tags: ['t-work', 't-home']),
        _task('workOnly', tags: ['t-work']),
        _task('none'),
      ];
      final groups = groupTasks(tasks, grouping: TaskGrouping.tag, tags: tags);

      // Ordered by tag name: home, work, then untagged.
      expect(groups.map((g) => g.label), ['home', 'work', 'Untagged']);
      expect(_ids(groups[0]), ['both']); // home
      expect(_ids(groups[1]), ['both', 'workOnly']); // work
      expect(_ids(groups[2]), ['none']); // untagged
      expect(groups[1].tag?.id, 't-work',
          reason: 'tag groups carry the tag for progress display');
    });

    test('a task whose tags are all unknown falls into untagged', () {
      final tasks = [_task('x', tags: ['ghost'])];
      final groups = groupTasks(tasks, grouping: TaskGrouping.tag);
      expect(groups.single.label, 'Untagged');
      expect(_ids(groups.single), ['x']);
    });

    test('tagAndFlags subdivides each tag group by importance/urgency', () {
      final tags = [_tag('t', 'proj')];
      final tasks = [
        _task('p1', urgent: true, important: true, tags: ['t']),
        _task('p4', tags: ['t']),
      ];
      final groups =
          groupTasks(tasks, grouping: TaskGrouping.tagAndFlags, tags: tags);
      expect(groups, hasLength(1));
      expect(groups.single.label, 'proj');
      expect(groups.single.subgroups.map((g) => g.quadrant), [1, 4]);
      expect(_ids(groups.single.subgroups.first), ['p1']);
    });
  });
}
