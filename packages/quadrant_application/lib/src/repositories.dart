import 'package:quadrant_domain/quadrant_domain.dart';

import 'queries/task_query.dart';
import 'recurrence/recurrence_record.dart';

/// Persistence interface for tasks. Implemented by `quadrant_store`;
/// synchronous because the store is an in-process SQLite database owned by
/// the backend.
abstract interface class TaskRepository {
  Task? findById(String id);

  /// Non-deleted tasks matching [query], in the query's sort order.
  List<Task> query(TaskQuery query);

  /// Non-deleted tasks with at least one scheduled side (start or due),
  /// filtered by [status]. Order is unspecified; the agenda read model
  /// re-sorts by task-local date.
  List<Task> scheduled(StatusFilter status);

  void insert(Task task);

  /// Persists a new state of an existing task (matched by id).
  void update(Task task);

  /// Ids of non-deleted tags assigned to the task, name-ordered.
  List<String> tagIdsOf(String taskId);

  bool hasTag(String taskId, String tagId);

  void assignTag(String taskId, String tagId);

  void removeTag(String taskId, String tagId);
}

/// Persistence interface for recurrence rules, materialized occurrences,
/// and exceptions.
abstract interface class RecurrenceRepository {
  RecurrenceRuleRecord? findRuleById(String id);

  void insertRule(RecurrenceRuleRecord rule);

  /// Rules currently linked from a non-deleted task, with that task's id.
  List<({RecurrenceRuleRecord rule, String taskId})> activeRuleBindings();

  TaskOccurrence? findOccurrenceById(String id);

  /// Original dates already materialized for the rule (any status).
  Set<PlainDate> materializedDates(String ruleId);

  /// Occurrences whose original date lies in `[from, to]`, ascending by
  /// original date then id.
  List<TaskOccurrence> occurrencesBetween(
    PlainDate from,
    PlainDate to, {
    OccurrenceFilter status = OccurrenceFilter.all,
    String? taskId,
  });

  void insertOccurrence(TaskOccurrence occurrence);

  void updateOccurrence(TaskOccurrence occurrence);

  /// Removes the rule's open occurrences; settled ones stay as history.
  void deleteOpenOccurrences(String ruleId);

  RecurrenceException? findException(String ruleId, PlainDate originalDate);

  /// Insert-or-replace, keyed by (rule, original date).
  void upsertException(RecurrenceException exception);

  void deleteException(String ruleId, PlainDate originalDate);
}

/// Persistence interface for reminders.
abstract interface class ReminderRepository {
  Reminder? findById(String id);

  /// Every reminder; the service filters and sorts (personal scale).
  List<Reminder> list();

  void insert(Reminder reminder);

  void update(Reminder reminder);

  void delete(String id);
}

/// Persistence interface for tags.
abstract interface class TagRepository {
  Tag? findById(String id);

  Tag? findActiveByName(String name);

  /// Non-deleted tags, name-ordered.
  List<Tag> listActive();

  /// Progress across non-deleted tasks carrying the tag.
  TagProgress progressOf(String tagId);

  void insert(Tag tag);

  void update(Tag tag);
}
