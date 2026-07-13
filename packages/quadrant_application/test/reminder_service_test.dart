import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

final now = DateTime.utc(2026, 7, 1, 12);

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryRecurrenceRepository recurrence;
  late InMemoryReminderRepository reminders;
  late ReminderService service;
  late TaskService taskService;

  setUp(() {
    tasks = InMemoryTaskRepository();
    recurrence = InMemoryRecurrenceRepository(tasks);
    reminders = InMemoryReminderRepository();
    service = ReminderService(reminders, tasks, recurrence, clock: () => now);
    taskService = TaskService(tasks, _NoTags(), clock: () => now);
  });

  Task addTask({TaskSchedule? schedule}) {
    final task = Task(
      id: EntityId.generate(),
      title: 'task',
      notes: '',
      isUrgent: false,
      isImportant: false,
      schedule: schedule ??
          TaskSchedule(
            dueKind: ScheduleKind.datetime,
            dueAtUtc: DateTime.utc(2026, 7, 20, 20),
            timezoneId: 'America/Chicago',
          ),
      createdAt: now,
      updatedAt: now,
    );
    tasks.insert(task);
    return task;
  }

  group('creation', () {
    test('relative_due computes the effective trigger from the task', () {
      final task = addTask();
      final created = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.relativeDue,
        offsetMinutes: 30,
      );
      expect(created.effectiveTriggerAt, DateTime.utc(2026, 7, 20, 19, 30));
      expect(created.reminder.state, ReminderState.pending);
    });

    test('relative reminders reject date-only sides', () {
      final task = addTask(
        schedule: TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
      );
      expect(
        () => service.create(
          taskId: task.id,
          trigger: ReminderTrigger.relativeDue,
          offsetMinutes: 30,
        ),
        throwsA(isA<DomainValidationError>()),
      );
    });

    test('absolute reminders carry their own instant', () {
      final task = addTask();
      final created = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.absolute,
        triggerAtUtc: DateTime.utc(2026, 7, 19, 9),
      );
      expect(created.effectiveTriggerAt, DateTime.utc(2026, 7, 19, 9));
    });

    test('shape violations and dangling references fail', () {
      final task = addTask();
      expect(
        () => service.create(
            taskId: task.id, trigger: ReminderTrigger.absolute),
        throwsA(isA<DomainValidationError>()),
      );
      expect(
        () => service.create(
          taskId: EntityId.generate(),
          trigger: ReminderTrigger.absolute,
          triggerAtUtc: now,
        ),
        throwsA(isA<EntityNotFoundException>()),
      );
      expect(
        () => service.create(
          taskId: task.id,
          occurrenceId: 'also-set',
          trigger: ReminderTrigger.absolute,
          triggerAtUtc: now,
        ),
        throwsA(isA<DomainValidationError>()),
      );
    });
  });

  group('recovery semantics', () {
    test('effective trigger follows a rescheduled task, never a cache',
        () {
      final task = addTask();
      final created = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.relativeDue,
        offsetMinutes: 60,
      );
      // The task's due moves by a day; the reminder must follow on the
      // next read without any write to the reminder.
      taskService.update(
        task.id,
        schedule: SchedulePatch(dueAtUtc: DateTime.utc(2026, 7, 21, 20)),
      );
      expect(
        service.get(created.reminder.id).effectiveTriggerAt,
        DateTime.utc(2026, 7, 21, 19),
      );
    });

    test('clearing the referenced side makes the trigger unresolvable',
        () {
      final task = addTask();
      final created = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.relativeDue,
        offsetMinutes: 60,
      );
      taskService.update(task.id,
          schedule: const SchedulePatch(dueKind: ScheduleKind.none));
      expect(service.get(created.reminder.id).effectiveTriggerAt, isNull);
    });

    test('horizon query sorts by effective trigger and honors until', () {
      final task = addTask();
      final late = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.absolute,
        triggerAtUtc: DateTime.utc(2026, 7, 22, 9),
      );
      final early = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.absolute,
        triggerAtUtc: DateTime.utc(2026, 7, 18, 9),
      );
      final all = service.list();
      expect(all.first.reminder.id, early.reminder.id);
      final horizon = service.list(until: DateTime.utc(2026, 7, 19));
      expect(horizon.map((r) => r.reminder.id), [early.reminder.id]);
      expect(horizon, isNot(contains(late)));
    });

    test('pending without a platform id discards the stale schedule', () {
      final task = addTask();
      final created = service.create(
        taskId: task.id,
        trigger: ReminderTrigger.absolute,
        triggerAtUtc: DateTime.utc(2026, 7, 19, 9),
      );
      final scheduled = service.update(
        created.reminder.id,
        state: ReminderState.scheduled,
        platformScheduleIdProvided: true,
        platformScheduleId: 'os-notification-42',
      );
      expect(scheduled.reminder.platformScheduleId, 'os-notification-42');

      final recovered = service.update(created.reminder.id,
          state: ReminderState.pending);
      expect(recovered.reminder.platformScheduleId, isNull,
          reason: 'recovery resets stale platform schedules');
    });
  });
}

class _NoTags implements TagRepository {
  @override
  Tag? findById(String id) => null;

  @override
  Tag? findActiveByName(String name) => null;

  @override
  List<Tag> listActive() => const [];

  @override
  TagProgress progressOf(String tagId) =>
      const TagProgress(completed: 0, total: 0);

  @override
  void insert(Tag tag) {}

  @override
  void update(Tag tag) {}
}
