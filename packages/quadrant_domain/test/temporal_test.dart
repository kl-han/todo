import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 1, 1);
final t1 = DateTime.utc(2026, 1, 2);

Task _task({TaskSchedule schedule = const TaskSchedule.none()}) => Task(
      id: EntityId.generate(),
      title: 'title',
      notes: '',
      isUrgent: false,
      isImportant: false,
      schedule: schedule,
      createdAt: t0,
      updatedAt: t0,
    );

void main() {
  group('PlainDate', () {
    test('parses and prints ISO dates strictly', () {
      expect(PlainDate.parse('2026-07-20').toString(), '2026-07-20');
      expect(() => PlainDate.parse('2026-7-20'),
          throwsA(isA<DomainValidationError>()));
      expect(() => PlainDate.parse('2026-07-20T00:00:00Z'),
          throwsA(isA<DomainValidationError>()));
    });

    test('rejects impossible calendar dates', () {
      expect(() => PlainDate.parse('2026-02-29'),
          throwsA(isA<DomainValidationError>()));
      expect(PlainDate.parse('2028-02-29').day, 29); // leap year
      expect(() => PlainDate.parse('2100-02-29'), // century, not leap
          throwsA(isA<DomainValidationError>()));
      expect(() => PlainDate.parse('2026-04-31'),
          throwsA(isA<DomainValidationError>()));
      expect(() => PlainDate.parse('2026-13-01'),
          throwsA(isA<DomainValidationError>()));
    });

    test('orders and measures like a calendar', () {
      final a = PlainDate.parse('2026-02-28');
      final b = PlainDate.parse('2026-03-01');
      expect(a.isBefore(b), isTrue);
      expect(b.differenceInDays(a), 1); // 2026 is not a leap year
      expect(a.addDays(1), b);
      expect(PlainDate.parse('2028-02-28').addDays(1),
          PlainDate.parse('2028-02-29'));
    });
  });

  group('TaskSchedule invariants', () {
    test('date kind requires the date and forbids the instant', () {
      expect(
        () => TaskSchedule(dueKind: ScheduleKind.date),
        throwsA(isA<DomainValidationError>()),
      );
      expect(
        () => TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
          dueAtUtc: t0,
        ),
        throwsA(isA<DomainValidationError>()),
      );
      final schedule = TaskSchedule(
        dueKind: ScheduleKind.date,
        dueDate: PlainDate.parse('2026-07-20'),
      );
      expect(schedule.isScheduled, isTrue);
      expect(schedule.timezoneId, isNull);
    });

    test('datetime kind requires a UTC instant and a timezone', () {
      expect(
        () => TaskSchedule(dueKind: ScheduleKind.datetime, dueAtUtc: t0),
        throwsA(isA<DomainValidationError>()),
      );
      expect(
        () => TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime(2026, 7, 20, 15), // not UTC-flagged
          timezoneId: 'America/Chicago',
        ),
        throwsA(isA<DomainValidationError>()),
      );
      final schedule = TaskSchedule(
        dueKind: ScheduleKind.datetime,
        dueAtUtc: DateTime.utc(2026, 7, 20, 20),
        timezoneId: 'America/Chicago',
      );
      expect(schedule.dueAtUtc!.isUtc, isTrue);
    });

    test('none kind forbids values, and timezone needs a datetime side',
        () {
      expect(
        () => TaskSchedule(startDate: PlainDate.parse('2026-07-20')),
        throwsA(isA<DomainValidationError>()),
      );
      expect(
        () => TaskSchedule(timezoneId: 'America/Chicago'),
        throwsA(isA<DomainValidationError>()),
      );
      expect(const TaskSchedule.none().isScheduled, isFalse);
    });
  });

  group('Task schedule transitions', () {
    test('edit replaces the schedule and bumps the version', () {
      final task = _task();
      final due = TaskSchedule(
        dueKind: ScheduleKind.date,
        dueDate: PlainDate.parse('2026-07-20'),
      );
      final edited = task.edit(t1, schedule: due);
      expect(edited.schedule.dueDate, PlainDate.parse('2026-07-20'));
      expect(edited.version, task.version + 1);
    });

    test('schedule never changes the quadrant', () {
      final scheduled = _task(
        schedule: TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
      );
      expect(scheduled.quadrant, Quadrant.q4);
    });

    test('estimated minutes can be set and cleared', () {
      final task = _task().edit(t1, estimatedMinutes: () => 25);
      expect(task.estimatedMinutes, 25);
      final cleared = task.edit(t1, estimatedMinutes: () => null);
      expect(cleared.estimatedMinutes, isNull);
      final untouched = cleared.edit(t1, title: 'x');
      expect(untouched.estimatedMinutes, isNull);
    });
  });

  group('estimated minutes validation', () {
    test('accepts 1..maxEstimatedMinutes and rejects outside', () {
      expect(validateEstimatedMinutes(1), 1);
      expect(validateEstimatedMinutes(maxEstimatedMinutes),
          maxEstimatedMinutes);
      expect(() => validateEstimatedMinutes(0),
          throwsA(isA<DomainValidationError>()));
      expect(() => validateEstimatedMinutes(maxEstimatedMinutes + 1),
          throwsA(isA<DomainValidationError>()));
    });
  });
}
