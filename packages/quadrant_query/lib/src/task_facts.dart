/// The task metadata a filter rule is evaluated against.
///
/// A small value object rather than the full `Task` entity: a rule only
/// reads importance, urgency, and the task's tag names. The application
/// layer builds these from a task and its tag set before applying the
/// reference evaluator.
class TaskFacts {
  TaskFacts({
    required this.isImportant,
    required this.isUrgent,
    required Set<String> tagNames,
  }) : tagNames = Set.unmodifiable(tagNames);

  final bool isImportant;
  final bool isUrgent;
  final Set<String> tagNames;

  bool hasTag(String name) => tagNames.contains(name);
}
