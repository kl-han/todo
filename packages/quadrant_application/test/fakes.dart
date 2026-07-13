import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';

/// In-memory repositories for application service tests. Storage
/// semantics are covered by quadrant_store; these fakes only mirror the
/// repository contracts.
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, Task> tasks = {};

  @override
  Task? findById(String id) => tasks[id];

  @override
  List<Task> query(TaskQuery query) => throw UnimplementedError();

  @override
  List<Task> scheduled(StatusFilter status) => tasks.values.where((task) {
        if (task.isDeleted || !task.schedule.isScheduled) return false;
        return switch (status) {
          StatusFilter.open => task.status == TaskStatus.open,
          StatusFilter.completed => task.status == TaskStatus.completed,
          StatusFilter.all => true,
        };
      }).toList();

  @override
  void insert(Task task) => tasks[task.id] = task;

  @override
  void update(Task task) => tasks[task.id] = task;

  @override
  List<String> tagIdsOf(String taskId) => const [];

  @override
  bool hasTag(String taskId, String tagId) => false;

  @override
  void assignTag(String taskId, String tagId) {}

  @override
  void removeTag(String taskId, String tagId) {}
}

class InMemoryRecurrenceRepository implements RecurrenceRepository {
  InMemoryRecurrenceRepository(this._tasks);

  final InMemoryTaskRepository _tasks;
  final Map<String, RecurrenceRuleRecord> rules = {};
  final Map<String, TaskOccurrence> occurrences = {};
  final Map<(String, String), RecurrenceException> exceptions = {};

  @override
  RecurrenceRuleRecord? findRuleById(String id) => rules[id];

  @override
  void insertRule(RecurrenceRuleRecord rule) => rules[rule.id] = rule;

  @override
  List<({RecurrenceRuleRecord rule, String taskId})> activeRuleBindings() => [
        for (final task in _tasks.tasks.values)
          if (!task.isDeleted && rules.containsKey(task.recurrenceRuleId))
            (rule: rules[task.recurrenceRuleId]!, taskId: task.id),
      ];

  @override
  TaskOccurrence? findOccurrenceById(String id) => occurrences[id];

  @override
  Set<PlainDate> materializedDates(String ruleId) => {
        for (final occurrence in occurrences.values)
          if (occurrence.recurrenceRuleId == ruleId) occurrence.originalDate,
      };

  @override
  List<TaskOccurrence> occurrencesBetween(
    PlainDate from,
    PlainDate to, {
    OccurrenceFilter status = OccurrenceFilter.all,
    String? taskId,
  }) {
    final result = occurrences.values.where((occurrence) {
      if (occurrence.originalDate.isBefore(from) ||
          occurrence.originalDate.isAfter(to)) {
        return false;
      }
      if (!status.matches(occurrence.status)) return false;
      if (taskId != null && occurrence.taskId != taskId) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final byDate = a.originalDate.compareTo(b.originalDate);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return result;
  }

  @override
  void insertOccurrence(TaskOccurrence occurrence) =>
      occurrences[occurrence.id] = occurrence;

  @override
  void updateOccurrence(TaskOccurrence occurrence) =>
      occurrences[occurrence.id] = occurrence;

  @override
  void deleteOpenOccurrences(String ruleId) => occurrences.removeWhere(
        (_, occurrence) =>
            occurrence.recurrenceRuleId == ruleId &&
            occurrence.status == OccurrenceStatus.open,
      );

  @override
  RecurrenceException? findException(String ruleId, PlainDate originalDate) =>
      exceptions[(ruleId, originalDate.toString())];

  @override
  void upsertException(RecurrenceException exception) =>
      exceptions[(exception.recurrenceRuleId,
          exception.originalDate.toString())] = exception;

  @override
  void deleteException(String ruleId, PlainDate originalDate) =>
      exceptions.remove((ruleId, originalDate.toString()));
}

class InMemoryReminderRepository implements ReminderRepository {
  final Map<String, Reminder> reminders = {};

  @override
  Reminder? findById(String id) => reminders[id];

  @override
  List<Reminder> list() =>
      reminders.values.toList()..sort((a, b) => a.id.compareTo(b.id));

  @override
  void insert(Reminder reminder) => reminders[reminder.id] = reminder;

  @override
  void update(Reminder reminder) => reminders[reminder.id] = reminder;

  @override
  void delete(String id) => reminders.remove(id);
}

class InMemoryFocusSessionRepository implements FocusSessionRepository {
  final Map<String, FocusSession> _sessions = {};

  @override
  FocusSession? findById(String id) => _sessions[id];

  @override
  FocusSession? findActive() {
    for (final session in _sessions.values) {
      if (session.isActive) return session;
    }
    return null;
  }

  @override
  List<FocusSession> list({bool? active, String? taskId}) {
    final result = _sessions.values.where((session) {
      if (active != null && session.isActive != active) return false;
      if (taskId != null && session.taskId != taskId) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final byStart = b.startedAt.compareTo(a.startedAt);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
    return result;
  }

  @override
  void insert(FocusSession session) => _sessions[session.id] = session;

  @override
  void update(FocusSession session) => _sessions[session.id] = session;
}
