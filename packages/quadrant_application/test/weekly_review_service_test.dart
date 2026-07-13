import 'dart:convert';

import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

// Week under review: Monday 2026-06-29 .. Sunday 2026-07-05. The clock
// sits the following Friday so staleness is deterministic.
final weekStart = PlainDate.parse('2026-06-29');
final now = DateTime.utc(2026, 7, 10, 12);

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryRecurrenceRepository recurrence;
  late InMemoryFocusSessionRepository sessions;
  late InMemoryPlanningRepository plans;
  late InMemoryReportRepository reports;
  late WeeklyReviewService service;
  late PlanningService planning;
  late FocusService focus;

  setUp(() {
    tasks = InMemoryTaskRepository();
    recurrence = InMemoryRecurrenceRepository(tasks);
    sessions = InMemoryFocusSessionRepository();
    plans = InMemoryPlanningRepository();
    reports = InMemoryReportRepository();
    service = WeeklyReviewService(
        tasks, recurrence, sessions, plans, reports, clock: () => now);
    planning = PlanningService(plans, tasks, recurrence, sessions,
        clock: () => now);
    focus = FocusService(sessions, tasks, recurrence,
        clock: () => DateTime.utc(2026, 7, 1, 9));
  });

  Task addTask({
    bool urgent = false,
    bool important = false,
    DateTime? completedAt,
    DateTime? updatedAt,
    TaskSchedule? schedule,
  }) {
    final task = Task(
      id: EntityId.generate(),
      title: 'task',
      notes: '',
      isUrgent: urgent,
      isImportant: important,
      schedule: schedule ?? const TaskSchedule.none(),
      createdAt: DateTime.utc(2026, 6, 1),
      updatedAt: updatedAt ?? DateTime.utc(2026, 6, 1),
      completedAt: completedAt,
    );
    tasks.insert(task);
    return task;
  }

  test('week_start must be a Monday', () {
    expect(
      () => service.report(PlainDate.parse('2026-07-01')),
      throwsA(isA<DomainValidationError>()),
    );
  });

  test('completed counts split by quadrant and honor the week window', () {
    addTask(urgent: true, important: true,
        completedAt: DateTime.utc(2026, 6, 30, 10));
    addTask(important: true, completedAt: DateTime.utc(2026, 7, 4, 10));
    addTask(completedAt: DateTime.utc(2026, 7, 8, 10)); // next week
    final report = service.report(weekStart);
    expect(report.completedByQuadrant, {1: 1, 2: 1, 3: 0, 4: 0});
  });

  test('due performance: on-time, late, and overdue-open', () {
    TaskSchedule dueOn(String date) => TaskSchedule(
        dueKind: ScheduleKind.date, dueDate: PlainDate.parse(date));
    addTask(schedule: dueOn('2026-07-01'),
        completedAt: DateTime.utc(2026, 7, 1, 8)); // on time
    addTask(schedule: dueOn('2026-07-01'),
        completedAt: DateTime.utc(2026, 7, 3, 8)); // late
    addTask(schedule: dueOn('2026-07-02')); // still open, past due
    final report = service.report(weekStart);
    expect(report.duePerformance,
        (onTime: 1, late: 1, overdueOpen: 1));
  });

  test('focus, Q2 investment, plan accuracy, and carryover compose', () {
    final q2 = addTask(important: true);
    final session = focus.start(taskId: q2.id, plannedFocusSeconds: 1500);
    // finish 25 minutes later
    final finisher = FocusService(sessions, tasks, recurrence,
        clock: () => DateTime.utc(2026, 7, 1, 9, 25));
    finisher.finish(session.id, FocusResult.completed);

    planning.addItem(PlainDate.parse('2026-07-01'),
        taskId: q2.id, plannedMinutes: 50);
    final item = planning.addItem(PlainDate.parse('2026-07-02'),
        taskId: addTask().id, plannedMinutes: 30);
    planning.updateItem(PlainDate.parse('2026-07-02'), item.id,
        outcome: () => PlanOutcome.skipped);

    final report = service.report(weekStart);
    expect(report.focus.sessionCount, 1);
    expect(report.focus.activeSeconds, 1500);
    expect(report.q2FocusSeconds, 1500);
    expect(report.planAccuracy,
        (plannedMinutes: 80, actualFocusSeconds: 1500));
    expect(report.carryover.plannedItems, 2);
    expect(report.carryover.withoutOutcome, 1);
    expect(report.carryover.skipped, 1);
  });

  test('delegated follow-up and stale Q4 cleanup candidates', () {
    addTask(urgent: true); // open Q3
    addTask(updatedAt: DateTime.utc(2026, 6, 20)); // Q4, 20 days stale
    addTask(updatedAt: DateTime.utc(2026, 7, 9)); // Q4, fresh
    final report = service.report(weekStart);
    expect(report.openQ3Tasks, 1);
    expect(report.staleQ4Tasks, 1);
  });

  test('finalize stores a versioned snapshot; reads round-trip', () {
    addTask(completedAt: DateTime.utc(2026, 7, 1, 8));
    final snapshot =
        service.finalize(weekStart, userNotes: 'good week');
    expect(snapshot.reportVersion, weeklyReportVersion);
    expect(snapshot.userNotes, 'good week');
    final summary =
        jsonDecode(snapshot.summaryJson) as Map<String, Object?>;
    expect((summary['completed'] as Map<String, Object?>)['q4'], 1);

    final read = service.snapshot(weekStart);
    expect(read.summaryJson, snapshot.summaryJson);
    expect(
      () => service.snapshot(PlainDate.parse('2026-07-06')),
      throwsA(isA<EntityNotFoundException>()),
    );
  });

  test('CSV export flattens every section', () {
    final csv = service.report(weekStart).toCsv();
    expect(csv, startsWith('section,metric,value\n'));
    for (final section in [
      'completed', 'carryover', 'due_performance', 'focus',
      'plan_accuracy', 'q2_investment', 'delegated_followup',
      'cleanup_candidates',
    ]) {
      expect(csv, contains('$section,'));
    }
  });
}
