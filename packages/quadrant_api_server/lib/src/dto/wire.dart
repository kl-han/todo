import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';

/// Wire encoding of domain objects. This is the only place task/tag JSON
/// shapes are defined server-side; the shapes are normative in
/// `api/openapi.yaml`.

String encodeInstant(DateTime time) => time.toUtc().toIso8601String();

Map<String, Object?> taskToJson(Task task, List<String> tagIds) => {
      'id': task.id,
      'title': task.title,
      'notes': task.notes,
      'is_urgent': task.isUrgent,
      'is_important': task.isImportant,
      'status': task.status.wireName,
      'quadrant': task.quadrant.number,
      'start_kind': task.schedule.startKind.wireName,
      // Plain YYYY-MM-DD; date-only values never become instants.
      'start_date': task.schedule.startDate?.toString(),
      'start_at_utc': task.schedule.startAtUtc == null
          ? null
          : encodeInstant(task.schedule.startAtUtc!),
      'due_kind': task.schedule.dueKind.wireName,
      'due_date': task.schedule.dueDate?.toString(),
      'due_at_utc': task.schedule.dueAtUtc == null
          ? null
          : encodeInstant(task.schedule.dueAtUtc!),
      'timezone_id': task.schedule.timezoneId,
      'estimated_minutes': task.estimatedMinutes,
      'recurrence_rule_id': task.recurrenceRuleId,
      'completed_at':
          task.completedAt == null ? null : encodeInstant(task.completedAt!),
      'created_at': encodeInstant(task.createdAt),
      'updated_at': encodeInstant(task.updatedAt),
      'deleted_at':
          task.deletedAt == null ? null : encodeInstant(task.deletedAt!),
      'version': task.version,
      'tag_ids': tagIds,
    };

Map<String, Object?> recurrenceToJson(
        RecurrenceRuleRecord rule, String taskId) =>
    {
      'id': rule.id,
      'task_id': taskId,
      'dtstart': rule.dtstart.toString(),
      'rrule': rule.rrule,
      'created_at': encodeInstant(rule.createdAt),
      'updated_at': encodeInstant(rule.updatedAt),
    };

Map<String, Object?> occurrenceToJson(TaskOccurrence occurrence) => {
      'id': occurrence.id,
      'task_id': occurrence.taskId,
      'recurrence_rule_id': occurrence.recurrenceRuleId,
      'original_date': occurrence.originalDate.toString(),
      'kind': occurrence.kind.wireName,
      'occurrence_date': occurrence.date?.toString(),
      'occurrence_at_utc':
          occurrence.atUtc == null ? null : encodeInstant(occurrence.atUtc!),
      'status': occurrence.status.wireName,
      'completed_at': occurrence.completedAt == null
          ? null
          : encodeInstant(occurrence.completedAt!),
      'created_at': encodeInstant(occurrence.createdAt),
      'updated_at': encodeInstant(occurrence.updatedAt),
      'version': occurrence.version,
    };

Map<String, Object?> reminderToJson(ResolvedReminder resolved) {
  final reminder = resolved.reminder;
  return {
    'id': reminder.id,
    'task_id': reminder.taskId,
    'occurrence_id': reminder.occurrenceId,
    'trigger_type': reminder.trigger.wireName,
    'trigger_at_utc': reminder.triggerAtUtc == null
        ? null
        : encodeInstant(reminder.triggerAtUtc!),
    'offset_minutes': reminder.offsetMinutes,
    'effective_trigger_at_utc': resolved.effectiveTriggerAt == null
        ? null
        : encodeInstant(resolved.effectiveTriggerAt!),
    'channel': reminder.channel,
    'state': reminder.state.wireName,
    'platform_schedule_id': reminder.platformScheduleId,
    'created_at': encodeInstant(reminder.createdAt),
    'updated_at': encodeInstant(reminder.updatedAt),
    'version': reminder.version,
  };
}

Map<String, Object?> focusSessionToJson(FocusSession session) => {
      'id': session.id,
      'task_id': session.taskId,
      'occurrence_id': session.occurrenceId,
      'device_id': session.deviceId,
      'planned_focus_seconds': session.plannedFocusSeconds,
      'planned_break_seconds': session.plannedBreakSeconds,
      'phase': session.phase.wireName,
      'started_at': encodeInstant(session.startedAt),
      'ended_at':
          session.endedAt == null ? null : encodeInstant(session.endedAt!),
      'active_seconds': session.activeSeconds,
      'paused_seconds': session.pausedSeconds,
      'last_transition_at': encodeInstant(session.lastTransitionAt),
      'interruption_count': session.interruptionCount,
      'result': session.result?.wireName,
      'notes': session.notes,
      'created_at': encodeInstant(session.createdAt),
      'updated_at': encodeInstant(session.updatedAt),
      'version': session.version,
    };

Map<String, Object?> planToJson(DailyPlan plan, List<DailyPlanItem> items) =>
    {
      'id': plan.id,
      'local_date': plan.localDate.toString(),
      'planned_minutes':
          items.fold<int>(0, (sum, item) => sum + (item.plannedMinutes ?? 0)),
      'review_notes': plan.reviewNotes,
      'status': plan.status.wireName,
      'items': [for (final item in items) planItemToJson(item)],
      'created_at': encodeInstant(plan.createdAt),
      'updated_at': encodeInstant(plan.updatedAt),
      'version': plan.version,
    };

Map<String, Object?> planItemToJson(DailyPlanItem item) => {
      'id': item.id,
      'daily_plan_id': item.dailyPlanId,
      'task_id': item.taskId,
      'occurrence_id': item.occurrenceId,
      'position': item.position,
      'planned_minutes': item.plannedMinutes,
      'scheduled_start': item.scheduledStart,
      'outcome': item.outcome?.wireName,
      'created_at': encodeInstant(item.createdAt),
      'updated_at': encodeInstant(item.updatedAt),
      'version': item.version,
    };

Map<String, Object?> tagToJson(Tag tag, TagProgress progress) => {
      'id': tag.id,
      'name': tag.name,
      'color': tag.color,
      'created_at': encodeInstant(tag.createdAt),
      'updated_at': encodeInstant(tag.updatedAt),
      'version': tag.version,
      'progress': {
        'completed': progress.completed,
        'total': progress.total,
      },
    };
