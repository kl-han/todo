import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 1, 1);

class _FakeTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};

  @override
  Task? findById(String id) => _tasks[id];

  @override
  List<Task> query(TaskQuery query) => throw UnimplementedError();

  @override
  List<Task> scheduled(StatusFilter status) => _tasks.values.where((task) {
        if (task.isDeleted || !task.schedule.isScheduled) return false;
        return switch (status) {
          StatusFilter.open => task.status == TaskStatus.open,
          StatusFilter.completed => task.status == TaskStatus.completed,
          StatusFilter.all => true,
        };
      }).toList();

  @override
  void insert(Task task) => _tasks[task.id] = task;

  @override
  void update(Task task) => _tasks[task.id] = task;

  @override
  List<String> tagIdsOf(String taskId) => const [];

  @override
  bool hasTag(String taskId, String tagId) => false;

  @override
  void assignTag(String taskId, String tagId) {}

  @override
  void removeTag(String taskId, String tagId) {}
}

void main() {
  late _FakeTaskRepository repository;
  late AgendaService service;

  setUp(() {
    repository = _FakeTaskRepository();
    service = AgendaService(repository);
  });

  Task add(String id, TaskSchedule schedule, {DateTime? completedAt}) {
    final task = Task(
      id: id,
      title: id,
      notes: '',
      isUrgent: false,
      isImportant: false,
      schedule: schedule,
      createdAt: t0,
      updatedAt: t0,
      completedAt: completedAt,
    );
    repository.insert(task);
    return task;
  }

  AgendaReport agenda(String from, String to,
          {StatusFilter status = StatusFilter.open}) =>
      service.agenda(
        from: PlainDate.parse(from),
        to: PlainDate.parse(to),
        status: status,
      );

  group('grouping', () {
    test('date-only values keep their stored date in every timezone', () {
      // A date-only deadline must never shift by being interpreted as
      // midnight UTC.
      add(
        'date-only',
        TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
      );
      final report = agenda('2026-07-20', '2026-07-20');
      expect(report.days, hasLength(1));
      expect(report.days.single.date, PlainDate.parse('2026-07-20'));
      expect(report.days.single.entries.single.timeLocal, isNull);
    });

    test('datetime values group by the task-local date, not UTC', () {
      // 2026-07-21 03:30 UTC is still 2026-07-20 22:30 in Chicago.
      add(
        'evening',
        TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 7, 21, 3, 30),
          timezoneId: 'America/Chicago',
        ),
      );
      final report = agenda('2026-07-01', '2026-07-31');
      expect(report.days.single.date, PlainDate.parse('2026-07-20'));
      expect(report.days.single.entries.single.timeLocal, '22:30');
    });

    test('a task with start and due contributes two entries', () {
      add(
        'both',
        TaskSchedule(
          startKind: ScheduleKind.date,
          startDate: PlainDate.parse('2026-07-19'),
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
      );
      final report = agenda('2026-07-19', '2026-07-20');
      expect(report.days, hasLength(2));
      expect(report.days.first.entries.single.kind, AgendaEntryKind.start);
      expect(report.days.last.entries.single.kind, AgendaEntryKind.due);
    });

    test('days sort ascending, all-day entries before timed ones', () {
      add(
        'timed',
        TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 7, 20, 14),
          timezoneId: 'UTC',
        ),
      );
      add(
        'allday',
        TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
      );
      final entries = agenda('2026-07-20', '2026-07-20').days.single.entries;
      expect(entries.map((e) => e.task.id), ['allday', 'timed']);
    });

    test('status filter and range bounds apply', () {
      add(
        'done',
        TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
        completedAt: t0,
      );
      add(
        'outside',
        TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-08-01'),
        ),
      );
      expect(agenda('2026-07-20', '2026-07-25').days, isEmpty);
      expect(
        agenda('2026-07-20', '2026-07-25', status: StatusFilter.completed)
            .days,
        hasLength(1),
      );
    });
  });

  group('DST boundaries (America/Chicago)', () {
    test('spring-forward: instants in the missing hour stay on their day',
        () {
      // 2026-03-08 02:30 local does not exist; 08:30 UTC that morning is
      // 03:30 CDT after the jump.
      add(
        'spring',
        TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 3, 8, 8, 30),
          timezoneId: 'America/Chicago',
        ),
      );
      final report = agenda('2026-03-08', '2026-03-08');
      expect(report.days.single.entries.single.timeLocal, '03:30');
    });

    test('fall-back: both instants of the repeated hour render locally',
        () {
      // 2026-11-01 01:30 local happens twice: 06:30 UTC (CDT) and
      // 07:30 UTC (CST). Distinct instants, same wall clock.
      add(
        'first',
        TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 11, 1, 6, 30),
          timezoneId: 'America/Chicago',
        ),
      );
      add(
        'second',
        TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 11, 1, 7, 30),
          timezoneId: 'America/Chicago',
        ),
      );
      final entries = agenda('2026-11-01', '2026-11-01').days.single.entries;
      expect(entries, hasLength(2));
      expect(entries[0].timeLocal, '01:30');
      expect(entries[1].timeLocal, '01:30');
    });
  });

  group('range validation', () {
    test('rejects inverted and oversized ranges', () {
      expect(
        () => agenda('2026-07-21', '2026-07-20'),
        throwsA(isA<DomainValidationError>()),
      );
      expect(
        () => agenda('2026-01-01', '2027-01-02'),
        throwsA(isA<DomainValidationError>()),
      );
    });
  });
}
