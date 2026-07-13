import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

// A fixed clock keeps the materialization horizon deterministic.
final now = DateTime.utc(2026, 7, 1, 12);

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryRecurrenceRepository recurrence;
  late RecurrenceService service;

  setUp(() {
    tasks = InMemoryTaskRepository();
    recurrence = InMemoryRecurrenceRepository(tasks);
    service = RecurrenceService(tasks, recurrence, clock: () => now);
  });

  Task addTask({TaskSchedule? schedule}) {
    final task = Task(
      id: EntityId.generate(),
      title: 'recurring',
      notes: '',
      isUrgent: false,
      isImportant: false,
      schedule: schedule ??
          TaskSchedule(
            dueKind: ScheduleKind.date,
            dueDate: PlainDate.parse('2026-07-06'),
          ),
      createdAt: now,
      updatedAt: now,
    );
    tasks.insert(task);
    return task;
  }

  group('setRecurrence', () {
    test('links the rule, bumps the task, and materializes the window',
        () {
      final task = addTask();
      final rule = service.setRecurrence(
        task.id,
        dtstart: PlainDate.parse('2026-07-06'),
        rrule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      expect(tasks.findById(task.id)!.recurrenceRuleId, rule.id);
      expect(tasks.findById(task.id)!.version, task.version + 1);

      final materialized = recurrence
          .occurrencesBetween(
              PlainDate.parse('2026-07-01'), PlainDate.parse('2026-10-01'))
          .map((o) => o.originalDate.toString());
      // Mondays from dtstart through now+90d (2026-09-29).
      expect(materialized.first, '2026-07-06');
      expect(materialized, contains('2026-09-28'));
      expect(materialized, isNot(contains('2026-10-05')));
    });

    test('requires a scheduled anchor side', () {
      final task = addTask(schedule: const TaskSchedule.none());
      expect(
        () => service.setRecurrence(task.id,
            dtstart: PlainDate.parse('2026-07-06'), rrule: 'FREQ=DAILY'),
        throwsA(isA<DomainValidationError>()),
      );
    });

    test('replacing a rule keeps settled history, drops open occurrences',
        () {
      final task = addTask();
      service.setRecurrence(task.id,
          dtstart: PlainDate.parse('2026-07-06'),
          rrule: 'FREQ=WEEKLY;BYDAY=MO');
      final first = service
          .occurrences(
              from: PlainDate.parse('2026-07-06'),
              to: PlainDate.parse('2026-07-06'))
          .single;
      service.setOccurrenceStatus(first.id, OccurrenceStatus.completed);

      service.setRecurrence(task.id,
          dtstart: PlainDate.parse('2026-07-07'),
          rrule: 'FREQ=WEEKLY;BYDAY=TU');

      final all = recurrence.occurrences.values.toList();
      // The completed Monday survives; open Mondays are gone; Tuesdays
      // belong to the new rule.
      expect(
        all.where((o) => o.status == OccurrenceStatus.completed).length,
        1,
      );
      expect(
        all.where((o) => o.status == OccurrenceStatus.open).every(
            (o) => o.recurrenceRuleId == tasks.findById(task.id)!.recurrenceRuleId),
        isTrue,
      );
    });
  });

  group('occurrences query', () {
    test('materialization is idempotent across repeated queries', () {
      final task = addTask();
      service.setRecurrence(task.id,
          dtstart: PlainDate.parse('2026-07-06'), rrule: 'FREQ=DAILY');
      final from = PlainDate.parse('2026-07-06');
      final to = PlainDate.parse('2026-07-10');
      final first = service.occurrences(from: from, to: to);
      final second = service.occurrences(from: from, to: to);
      expect(second.map((o) => o.id), first.map((o) => o.id));
      expect(first, hasLength(5));
    });

    test('extends beyond the initial horizon on demand', () {
      final task = addTask();
      service.setRecurrence(task.id,
          dtstart: PlainDate.parse('2026-07-06'),
          rrule: 'FREQ=WEEKLY;BYDAY=MO');
      // Well past now+90d.
      final far = service.occurrences(
          from: PlainDate.parse('2026-11-02'),
          to: PlainDate.parse('2026-11-30'));
      expect(far.map((o) => o.originalDate.toString()),
          ['2026-11-02', '2026-11-09', '2026-11-16', '2026-11-23', '2026-11-30']);
    });

    test('datetime tasks materialize DST-correct local wall times', () {
      // Due 09:30 America/Chicago. Across the 2026-11-01 fall-back the
      // UTC offset changes from -05:00 to -06:00, so the UTC instant
      // must move while the wall time stays 09:30.
      final task = addTask(
        schedule: TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 7, 6, 14, 30), // 09:30 CDT
          timezoneId: 'America/Chicago',
        ),
      );
      service.setRecurrence(task.id,
          dtstart: PlainDate.parse('2026-10-26'),
          rrule: 'FREQ=WEEKLY;BYDAY=MO');
      final around = service.occurrences(
          from: PlainDate.parse('2026-10-26'),
          to: PlainDate.parse('2026-11-02'));
      expect(around, hasLength(2));
      expect(around[0].atUtc, DateTime.utc(2026, 10, 26, 14, 30)); // CDT
      expect(around[1].atUtc, DateTime.utc(2026, 11, 2, 15, 30)); // CST
    });
  });

  group('occurrence lifecycle', () {
    late String occurrenceId;

    setUp(() {
      final task = addTask();
      service.setRecurrence(task.id,
          dtstart: PlainDate.parse('2026-07-06'),
          rrule: 'FREQ=WEEKLY;BYDAY=MO');
      occurrenceId = service
          .occurrences(
              from: PlainDate.parse('2026-07-06'),
              to: PlainDate.parse('2026-07-06'))
          .single
          .id;
    });

    test('completing one occurrence leaves siblings and the task open', () {
      final completed =
          service.setOccurrenceStatus(occurrenceId, OccurrenceStatus.completed);
      expect(completed.completedAt, now);
      final siblings = service.occurrences(
          from: PlainDate.parse('2026-07-13'),
          to: PlainDate.parse('2026-07-27'));
      expect(siblings.every((o) => o.status == OccurrenceStatus.open), isTrue);
      expect(tasks.tasks.values.single.status, TaskStatus.open);
    });

    test('skipping records an exception; reopening removes it', () {
      final skipped =
          service.setOccurrenceStatus(occurrenceId, OccurrenceStatus.skipped);
      expect(
        recurrence
            .findException(skipped.recurrenceRuleId, skipped.originalDate)!
            .type,
        RecurrenceExceptionType.skipped,
      );
      service.setOccurrenceStatus(occurrenceId, OccurrenceStatus.open);
      expect(
        recurrence.findException(
            skipped.recurrenceRuleId, skipped.originalDate),
        isNull,
      );
    });

    test('rescheduling moves the value but never the identity, and the '
        'moved date is not re-materialized', () {
      final moved = service.rescheduleOccurrence(occurrenceId,
          date: PlainDate.parse('2026-07-08'));
      expect(moved.date, PlainDate.parse('2026-07-08'));
      expect(moved.originalDate, PlainDate.parse('2026-07-06'));
      expect(
        recurrence
            .findException(moved.recurrenceRuleId, moved.originalDate)!
            .type,
        RecurrenceExceptionType.rescheduled,
      );
      // Re-querying must not resurrect a second 07-06 occurrence.
      final week = service.occurrences(
          from: PlainDate.parse('2026-07-06'),
          to: PlainDate.parse('2026-07-12'));
      expect(week, hasLength(1));
      expect(week.single.id, occurrenceId);
    });

    test('stale expected version conflicts', () {
      expect(
        () => service.setOccurrenceStatus(
            occurrenceId, OccurrenceStatus.completed,
            expectedVersion: 99),
        throwsA(isA<VersionConflictException>()),
      );
    });
  });
}
