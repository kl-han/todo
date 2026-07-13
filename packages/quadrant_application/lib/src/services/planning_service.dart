import 'package:quadrant_domain/quadrant_domain.dart';

import '../errors.dart';
import '../repositories.dart';

/// Planned versus actual for one day.
typedef PlanAccuracy = ({
  PlainDate localDate,
  int plannedMinutes,
  int actualFocusSeconds,
  int focusSessionCount,
});

/// Daily-plan commands and queries. A plan is a per-date singleton the
/// user fills deliberately — this service suggests nothing and
/// auto-fills nothing.
class PlanningService {
  PlanningService(
    this._plans,
    this._tasks,
    this._recurrence,
    this._sessions, {
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final PlanningRepository _plans;
  final TaskRepository _tasks;
  final RecurrenceRepository _recurrence;
  final FocusSessionRepository _sessions;
  final DateTime Function() _clock;

  /// The plan for [date], materialized empty on first read.
  DailyPlan plan(PlainDate date) {
    final existing = _plans.findPlanByDate(date);
    if (existing != null) return existing;
    final now = _clock();
    final plan = DailyPlan(
      id: EntityId.generate(),
      localDate: date,
      createdAt: now,
      updatedAt: now,
    );
    _plans.insertPlan(plan);
    return plan;
  }

  List<DailyPlanItem> items(PlainDate date) =>
      _plans.itemsOf(plan(date).id);

  DailyPlan review(
    PlainDate date, {
    String? reviewNotes,
    PlanStatus? status,
    int? expectedVersion,
  }) {
    var current = plan(date);
    _checkVersion(current.version, expectedVersion);
    current = current.review(_clock(),
        reviewNotes: reviewNotes, status: status);
    _plans.updatePlan(current);
    return current;
  }

  /// Appends a task or occurrence to the day. Duplicates conflict — the
  /// same piece of work belongs in a day once.
  DailyPlanItem addItem(
    PlainDate date, {
    String? taskId,
    String? occurrenceId,
    int? plannedMinutes,
    String? scheduledStart,
  }) {
    if (taskId != null) {
      final task = _tasks.findById(taskId);
      if (task == null || task.isDeleted) {
        throw EntityNotFoundException('No task $taskId.');
      }
    }
    if (occurrenceId != null &&
        _recurrence.findOccurrenceById(occurrenceId) == null) {
      throw EntityNotFoundException('No occurrence $occurrenceId.');
    }

    final target = plan(date);
    final existing = _plans.itemsOf(target.id);
    final duplicate = existing.any((item) =>
        (taskId != null && item.taskId == taskId) ||
        (occurrenceId != null && item.occurrenceId == occurrenceId));
    if (duplicate) {
      throw StateConflictException(
        'The referenced work is already planned for $date.',
      );
    }

    final now = _clock();
    final item = DailyPlanItem(
      id: EntityId.generate(),
      dailyPlanId: target.id,
      taskId: taskId,
      occurrenceId: occurrenceId,
      position: existing.isEmpty ? 0 : existing.last.position + 1,
      plannedMinutes: plannedMinutes,
      scheduledStart: scheduledStart,
      createdAt: now,
      updatedAt: now,
    );
    _plans.insertItem(item);
    return item;
  }

  DailyPlanItem updateItem(
    PlainDate date,
    String itemId, {
    int? position,
    int? Function()? plannedMinutes,
    String? Function()? scheduledStart,
    PlanOutcome? Function()? outcome,
    int? expectedVersion,
  }) {
    final item = _itemOf(date, itemId);
    _checkVersion(item.version, expectedVersion);
    final updated = item.update(
      _clock(),
      position: position,
      plannedMinutes: plannedMinutes,
      scheduledStart: scheduledStart,
      outcome: outcome,
    );
    _plans.updateItem(updated);
    return updated;
  }

  void removeItem(PlainDate date, String itemId, {int? expectedVersion}) {
    final item = _itemOf(date, itemId);
    _checkVersion(item.version, expectedVersion);
    _plans.deleteItem(itemId);
  }

  /// Planned minutes versus focus sessions started on that local date.
  /// Local dates come from the vault clock's local rendering, matching
  /// the plan's own date semantics.
  PlanAccuracy accuracy(PlainDate date) {
    final planned = _plans
        .itemsOf(plan(date).id)
        .fold(0, (sum, item) => sum + (item.plannedMinutes ?? 0));
    var actualSeconds = 0;
    var count = 0;
    for (final session in _sessions.list()) {
      if (PlainDate.of(session.startedAt.toLocal()) != date) continue;
      actualSeconds += session.activeSeconds;
      count += 1;
    }
    return (
      localDate: date,
      plannedMinutes: planned,
      actualFocusSeconds: actualSeconds,
      focusSessionCount: count,
    );
  }

  DailyPlanItem _itemOf(PlainDate date, String itemId) {
    final item = _plans.findItemById(itemId);
    if (item == null || item.dailyPlanId != plan(date).id) {
      throw EntityNotFoundException('No plan item $itemId on $date.');
    }
    return item;
  }

  void _checkVersion(int current, int? expected) {
    if (expected != null && expected != current) {
      throw VersionConflictException(currentVersion: current);
    }
  }
}
