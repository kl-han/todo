import 'dart:convert';

import 'package:quadrant_domain/quadrant_domain.dart';

import '../errors.dart';
import '../queries/task_query.dart';
import '../recurrence/recurrence_record.dart';
import '../repositories.dart';

/// The computed weekly report — facts only. Interpretations and
/// recommendations belong to the presentation layer; the backend never
/// judges an application or a week.
class WeeklyReport {
  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.completedByQuadrant,
    required this.completedOccurrences,
    required this.carryover,
    required this.duePerformance,
    required this.focus,
    required this.planAccuracy,
    required this.q2FocusSeconds,
    required this.openQ3Tasks,
    required this.staleQ4Tasks,
  });

  final PlainDate weekStart;
  final PlainDate weekEnd;

  /// Quadrant number (1–4) → tasks completed this week.
  final Map<int, int> completedByQuadrant;

  final int completedOccurrences;

  /// Planned items without a `done` outcome.
  final ({int plannedItems, int withoutOutcome, int skipped, int moved})
      carryover;

  final ({int onTime, int late, int overdueOpen}) duePerformance;

  final ({int sessionCount, int activeSeconds, int interruptionCount})
      focus;

  final ({int plannedMinutes, int actualFocusSeconds}) planAccuracy;

  /// Focus time on important/non-urgent work.
  final int q2FocusSeconds;

  /// Delegated follow-up: open Q3 tasks right now.
  final int openQ3Tasks;

  /// Cleanup candidates: open Q4 tasks untouched for 14+ days.
  final int staleQ4Tasks;

  Map<String, Object?> toJson() => {
        'week_start': weekStart.toString(),
        'week_end': weekEnd.toString(),
        'completed': {
          for (final entry in completedByQuadrant.entries)
            'q${entry.key}': entry.value,
          'occurrences': completedOccurrences,
        },
        'carryover': {
          'planned_items': carryover.plannedItems,
          'without_outcome': carryover.withoutOutcome,
          'skipped': carryover.skipped,
          'moved': carryover.moved,
        },
        'due_performance': {
          'on_time': duePerformance.onTime,
          'late': duePerformance.late,
          'overdue_open': duePerformance.overdueOpen,
        },
        'focus': {
          'session_count': focus.sessionCount,
          'active_seconds': focus.activeSeconds,
          'interruption_count': focus.interruptionCount,
        },
        'plan_accuracy': {
          'planned_minutes': planAccuracy.plannedMinutes,
          'actual_focus_seconds': planAccuracy.actualFocusSeconds,
        },
        'q2_investment': {'focus_seconds': q2FocusSeconds},
        'delegated_followup': {'open_q3_tasks': openQ3Tasks},
        'cleanup_candidates': {'stale_q4_tasks': staleQ4Tasks},
      };

  /// Flat `section,metric,value` rows for spreadsheet export.
  String toCsv() {
    final buffer = StringBuffer('section,metric,value\n');
    void section(String name, Map<String, Object?> values) {
      for (final entry in values.entries) {
        buffer.writeln('$name,${entry.key},${entry.value}');
      }
    }

    final json = toJson();
    for (final key in [
      'completed',
      'carryover',
      'due_performance',
      'focus',
      'plan_accuracy',
      'q2_investment',
      'delegated_followup',
      'cleanup_candidates',
    ]) {
      section(key, json[key]! as Map<String, Object?>);
    }
    return buffer.toString();
  }
}

/// A finalized snapshot of one week's report plus the user's notes.
class WeeklyReportSnapshot {
  const WeeklyReportSnapshot({
    required this.weekStart,
    required this.generatedAt,
    required this.reportVersion,
    required this.summaryJson,
    required this.userNotes,
  });

  final PlainDate weekStart;
  final DateTime generatedAt;
  final int reportVersion;
  final String summaryJson;
  final String userNotes;
}

/// Persistence for finalized weekly snapshots.
abstract interface class ReportRepository {
  WeeklyReportSnapshot? findSnapshot(PlainDate weekStart);

  /// Insert-or-replace, keyed by week start.
  void upsertSnapshot(WeeklyReportSnapshot snapshot);
}

/// How many days without an update make an open Q4 task a cleanup
/// candidate.
const int staleQ4Days = 14;

/// The report format this build emits; stored on snapshots so later
/// builds can migrate or refuse gracefully.
const int weeklyReportVersion = 1;

/// Computes the weekly review from the vault. Reports are normally
/// computed on demand; a snapshot is stored only when the user finalizes
/// one. Application-usage sections live with the agent's usage store and
/// join client-side — the vault never sees behavioral data.
class WeeklyReviewService {
  WeeklyReviewService(
    this._tasks,
    this._recurrence,
    this._sessions,
    this._plans,
    this._reports, {
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final TaskRepository _tasks;
  final RecurrenceRepository _recurrence;
  final FocusSessionRepository _sessions;
  final PlanningRepository _plans;
  final ReportRepository _reports;
  final DateTime Function() _clock;

  WeeklyReport report(PlainDate weekStart) {
    if (DateTime.utc(weekStart.year, weekStart.month, weekStart.day)
            .weekday !=
        DateTime.monday) {
      throw DomainValidationError('week_start must be a Monday.');
    }
    final weekEnd = weekStart.addDays(6);
    bool inWeek(PlainDate date) =>
        !date.isBefore(weekStart) && !date.isAfter(weekEnd);
    PlainDate localDate(DateTime instant) =>
        PlainDate.of(instant.toLocal());

    final allTasks = _tasks.query(const TaskQuery(status: StatusFilter.all));

    final completedByQuadrant = {1: 0, 2: 0, 3: 0, 4: 0};
    var onTime = 0;
    var late = 0;
    var overdueOpen = 0;
    var openQ3 = 0;
    var staleQ4 = 0;
    final now = _clock();

    for (final task in allTasks) {
      final completedAt = task.completedAt;
      if (completedAt != null && inWeek(localDate(completedAt))) {
        completedByQuadrant[task.quadrant.number] =
            completedByQuadrant[task.quadrant.number]! + 1;
      }
      // Due performance for dues that fall inside the week.
      final due = _dueLocalDate(task);
      if (due != null && inWeek(due)) {
        if (completedAt == null) {
          if (due.isBefore(localDate(now))) overdueOpen += 1;
        } else if (localDate(completedAt).isAfter(due)) {
          late += 1;
        } else {
          onTime += 1;
        }
      }
      if (task.status == TaskStatus.open) {
        if (task.quadrant == Quadrant.q3) openQ3 += 1;
        if (task.quadrant == Quadrant.q4 &&
            now.difference(task.updatedAt).inDays >= staleQ4Days) {
          staleQ4 += 1;
        }
      }
    }

    final completedOccurrences = _recurrence
        .occurrencesBetween(weekStart, weekEnd,
            status: OccurrenceFilter.completed)
        .length;

    var sessionCount = 0;
    var activeSeconds = 0;
    var interruptions = 0;
    var q2FocusSeconds = 0;
    for (final session in _sessions.list(active: false)) {
      if (!inWeek(localDate(session.startedAt))) continue;
      sessionCount += 1;
      activeSeconds += session.activeSeconds;
      interruptions += session.interruptionCount;
      final taskId = session.taskId;
      if (taskId != null) {
        final task = _tasks.findById(taskId);
        if (task != null && task.quadrant == Quadrant.q2) {
          q2FocusSeconds += session.activeSeconds;
        }
      }
    }

    var plannedItems = 0;
    var withoutOutcome = 0;
    var skipped = 0;
    var moved = 0;
    var plannedMinutes = 0;
    for (var offset = 0; offset < 7; offset++) {
      final plan = _plans.findPlanByDate(weekStart.addDays(offset));
      if (plan == null) continue;
      for (final item in _plans.itemsOf(plan.id)) {
        plannedItems += 1;
        plannedMinutes += item.plannedMinutes ?? 0;
        switch (item.outcome) {
          case null:
            withoutOutcome += 1;
          case PlanOutcome.skipped:
            skipped += 1;
          case PlanOutcome.moved:
            moved += 1;
          case PlanOutcome.done || PlanOutcome.partial:
            break;
        }
      }
    }

    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      completedByQuadrant: completedByQuadrant,
      completedOccurrences: completedOccurrences,
      carryover: (
        plannedItems: plannedItems,
        withoutOutcome: withoutOutcome,
        skipped: skipped,
        moved: moved,
      ),
      duePerformance:
          (onTime: onTime, late: late, overdueOpen: overdueOpen),
      focus: (
        sessionCount: sessionCount,
        activeSeconds: activeSeconds,
        interruptionCount: interruptions,
      ),
      planAccuracy: (
        plannedMinutes: plannedMinutes,
        actualFocusSeconds: activeSeconds,
      ),
      q2FocusSeconds: q2FocusSeconds,
      openQ3Tasks: openQ3,
      staleQ4Tasks: staleQ4,
    );
  }

  /// Stores (or replaces) the finalized snapshot for one week.
  WeeklyReportSnapshot finalize(PlainDate weekStart,
      {String userNotes = ''}) {
    final computed = report(weekStart);
    final snapshot = WeeklyReportSnapshot(
      weekStart: weekStart,
      generatedAt: _clock(),
      reportVersion: weeklyReportVersion,
      summaryJson: jsonEncode(computed.toJson()),
      userNotes: validateTaskNotes(userNotes),
    );
    _reports.upsertSnapshot(snapshot);
    return snapshot;
  }

  WeeklyReportSnapshot snapshot(PlainDate weekStart) {
    final stored = _reports.findSnapshot(weekStart);
    if (stored == null) {
      throw EntityNotFoundException('No snapshot for week $weekStart.');
    }
    return stored;
  }

  PlainDate? _dueLocalDate(Task task) {
    final schedule = task.schedule;
    return switch (schedule.dueKind) {
      ScheduleKind.none => null,
      ScheduleKind.date => schedule.dueDate,
      ScheduleKind.datetime => PlainDate.of(schedule.dueAtUtc!.toLocal()),
    };
  }

}
