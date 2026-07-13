import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:quadrant_temporal/quadrant_temporal.dart';
import 'package:timezone/timezone.dart' as tz;

import '../errors.dart';
import '../recurrence/recurrence_record.dart';
import '../repositories.dart';
import '../temporal/timezones.dart';

/// Maximum occurrence-query range, matching the agenda bound.
const int maxOccurrenceRangeDays = 366;

/// How far ahead of "today" occurrences are materialized when a rule is
/// attached; queries extend the window on demand.
const int defaultMaterializationDays = 90;

/// Recurrence commands and queries: rule lifecycle, idempotent occurrence
/// materialization, and per-occurrence exceptions. A recurring task is a
/// definition; each occurrence is its own record with its own history —
/// completing one never resets or touches the task or its siblings.
class RecurrenceService {
  RecurrenceService(this._tasks, this._recurrence, {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final TaskRepository _tasks;
  final RecurrenceRepository _recurrence;
  final DateTime Function() _clock;

  /// Attaches or replaces the task's rule and materializes the initial
  /// window. Replacing deletes the old rule's open occurrences; settled
  /// occurrences survive as history.
  RecurrenceRuleRecord setRecurrence(
    String taskId, {
    required PlainDate dtstart,
    required String rrule,
  }) {
    var task = _visibleTask(taskId);
    _anchorOf(task); // Validates that an anchor side exists.
    final rule = RecurrenceRule.parse(rrule);

    final now = _clock();
    final previousRuleId = task.recurrenceRuleId;
    if (previousRuleId != null) {
      _recurrence.deleteOpenOccurrences(previousRuleId);
    }
    final record = RecurrenceRuleRecord(
      id: EntityId.generate(),
      dtstart: dtstart,
      rrule: rule.toRrule(),
      createdAt: now,
      updatedAt: now,
    );
    _recurrence.insertRule(record);
    task = task.withRecurrenceRule(now, record.id);
    _tasks.update(task);

    final today = PlainDate.of(now);
    final horizon = today.addDays(defaultMaterializationDays);
    _materialize(record, task,
        from: dtstart, to: horizon.isBefore(dtstart) ? dtstart : horizon);
    return record;
  }

  RecurrenceRuleRecord getRecurrence(String taskId) {
    final task = _visibleTask(taskId);
    final ruleId = task.recurrenceRuleId;
    final rule = ruleId == null ? null : _recurrence.findRuleById(ruleId);
    if (rule == null) {
      throw EntityNotFoundException('Task $taskId does not recur.');
    }
    return rule;
  }

  /// Detaches the rule and deletes its open occurrences. Idempotent.
  void clearRecurrence(String taskId) {
    final task = _visibleTask(taskId);
    final ruleId = task.recurrenceRuleId;
    if (ruleId == null) return;
    _recurrence.deleteOpenOccurrences(ruleId);
    _tasks.update(task.withRecurrenceRule(_clock(), null));
  }

  /// Occurrences with an original date in `[from, to]`, materializing the
  /// range first so both backends answer identically for identical rules.
  List<TaskOccurrence> occurrences({
    required PlainDate from,
    required PlainDate to,
    OccurrenceFilter status = OccurrenceFilter.all,
    String? taskId,
  }) {
    if (to.isBefore(from)) {
      throw DomainValidationError('"to" must be on or after "from".');
    }
    if (to.differenceInDays(from) >= maxOccurrenceRangeDays) {
      throw DomainValidationError(
        'Occurrence range must not exceed $maxOccurrenceRangeDays days.',
      );
    }
    for (final binding in _recurrence.activeRuleBindings()) {
      if (taskId != null && binding.taskId != taskId) continue;
      final task = _tasks.findById(binding.taskId);
      if (task == null || task.isDeleted) continue;
      _materialize(binding.rule, task, from: from, to: to);
    }
    return _recurrence.occurrencesBetween(from, to,
        status: status, taskId: taskId);
  }

  TaskOccurrence getOccurrence(String id) {
    final occurrence = _recurrence.findOccurrenceById(id);
    if (occurrence == null) {
      throw EntityNotFoundException('No occurrence $id.');
    }
    return occurrence;
  }

  /// Completes, skips, or reopens one occurrence. Skipping records an
  /// exception; reopening a skipped occurrence removes it.
  TaskOccurrence setOccurrenceStatus(
    String id,
    OccurrenceStatus status, {
    int? expectedVersion,
  }) {
    var occurrence = getOccurrence(id);
    _checkVersion(occurrence.version, expectedVersion);
    if (occurrence.status == status) return occurrence;

    final now = _clock();
    final wasSkipped = occurrence.status == OccurrenceStatus.skipped;
    occurrence = switch (status) {
      OccurrenceStatus.completed => occurrence.complete(now),
      OccurrenceStatus.skipped => occurrence.skip(now),
      OccurrenceStatus.open => occurrence.reopen(now),
    };
    _recurrence.updateOccurrence(occurrence);

    if (status == OccurrenceStatus.skipped) {
      _recurrence.upsertException(RecurrenceException(
        recurrenceRuleId: occurrence.recurrenceRuleId,
        originalDate: occurrence.originalDate,
        type: RecurrenceExceptionType.skipped,
        createdAt: now,
      ));
    } else if (wasSkipped) {
      _recurrence.deleteException(
          occurrence.recurrenceRuleId, occurrence.originalDate);
    }
    return occurrence;
  }

  /// Moves one occurrence to a new date or instant (matching its kind)
  /// and records a rescheduled exception. The original date — the
  /// occurrence's identity — never changes.
  TaskOccurrence rescheduleOccurrence(
    String id, {
    PlainDate? date,
    DateTime? atUtc,
    int? expectedVersion,
  }) {
    var occurrence = getOccurrence(id);
    _checkVersion(occurrence.version, expectedVersion);
    if ((date == null) == (atUtc == null)) {
      throw DomainValidationError(
        'Reschedule with exactly one of occurrence_date and '
        'occurrence_at_utc.',
      );
    }
    final now = _clock();
    occurrence = date != null
        ? occurrence.rescheduleDate(now, date)
        : occurrence.rescheduleInstant(now, atUtc!);
    _recurrence.updateOccurrence(occurrence);
    _recurrence.upsertException(RecurrenceException(
      recurrenceRuleId: occurrence.recurrenceRuleId,
      originalDate: occurrence.originalDate,
      type: RecurrenceExceptionType.rescheduled,
      replacementDate: date,
      replacementAtUtc: atUtc,
      createdAt: now,
    ));
    return occurrence;
  }

  // ---- internals ----

  Task _visibleTask(String id) {
    final task = _tasks.findById(id);
    if (task == null || task.isDeleted) {
      throw EntityNotFoundException('No task $id.');
    }
    return task;
  }

  /// The schedule side occurrences repeat: due when present, else start.
  (OccurrenceKind, ScheduleKind) _anchorOf(Task task) {
    final schedule = task.schedule;
    if (schedule.dueKind != ScheduleKind.none) {
      return (OccurrenceKind.due, schedule.dueKind);
    }
    if (schedule.startKind != ScheduleKind.none) {
      return (OccurrenceKind.start, schedule.startKind);
    }
    throw DomainValidationError(
      'Recurrence requires a scheduled start or due side.',
    );
  }

  /// Inserts occurrences for every generated date in `[from, to]` that is
  /// not already materialized. Idempotent; existing occurrences (settled,
  /// rescheduled, or open) are never touched.
  void _materialize(
    RecurrenceRuleRecord record,
    Task task, {
    required PlainDate from,
    required PlainDate to,
  }) {
    final (kind, scheduleKind) = _anchorOf(task);
    final generator =
        OccurrenceGenerator(RecurrenceRule.parse(record.rrule), record.dtstart);
    final existing = _recurrence.materializedDates(record.id);
    final now = _clock();
    for (final date in generator.between(from, to)) {
      if (existing.contains(date)) continue;
      _recurrence.insertOccurrence(TaskOccurrence(
        id: EntityId.generate(),
        taskId: task.id,
        recurrenceRuleId: record.id,
        originalDate: date,
        kind: kind,
        date: scheduleKind == ScheduleKind.date ? date : null,
        atUtc: scheduleKind == ScheduleKind.datetime
            ? _instantOn(task, kind, date)
            : null,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  /// The task's anchor wall time on [date] in the task's timezone,
  /// converted to UTC per occurrence — which is exactly what makes
  /// occurrences DST-correct.
  DateTime _instantOn(Task task, OccurrenceKind kind, PlainDate date) {
    final schedule = task.schedule;
    final anchorUtc = kind == OccurrenceKind.due
        ? schedule.dueAtUtc!
        : schedule.startAtUtc!;
    final location = resolveTimezone(schedule.timezoneId!);
    final anchorLocal = tz.TZDateTime.from(anchorUtc, location);
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      anchorLocal.hour,
      anchorLocal.minute,
      anchorLocal.second,
    ).toUtc();
  }

  void _checkVersion(int current, int? expected) {
    if (expected != null && expected != current) {
      throw VersionConflictException(currentVersion: current);
    }
  }
}
