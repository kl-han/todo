import '../value_objects/quadrant.dart';
import '../value_objects/task_status.dart';

/// A task. Immutable; every state transition produces a new value with an
/// incremented [version] and a fresh [updatedAt], which is what the
/// optimistic-concurrency ETag protocol and the matrix sort key are built
/// on.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.isUrgent,
    required this.isImportant,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt,
    this.version = 1,
  });

  final String id;
  final String title;
  final String notes;
  final bool isUrgent;
  final bool isImportant;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final int version;

  TaskStatus get status =>
      completedAt == null ? TaskStatus.open : TaskStatus.completed;

  Quadrant get quadrant =>
      Quadrant.derive(isUrgent: isUrgent, isImportant: isImportant);

  bool get isDeleted => deletedAt != null;

  /// A modified copy with [version] incremented and [updatedAt] set to
  /// [now]. All mutations funnel through here so no edit can forget the
  /// concurrency bookkeeping.
  Task _next(
    DateTime now, {
    String? title,
    String? notes,
    bool? isUrgent,
    bool? isImportant,
    DateTime? Function()? completedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt,
      updatedAt: now,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
      version: version + 1,
    );
  }

  Task edit(
    DateTime now, {
    String? title,
    String? notes,
    bool? isUrgent,
    bool? isImportant,
  }) =>
      _next(now,
          title: title,
          notes: notes,
          isUrgent: isUrgent,
          isImportant: isImportant);

  Task complete(DateTime now) => _next(now, completedAt: () => now);

  Task reopen(DateTime now) => _next(now, completedAt: () => null);

  Task softDelete(DateTime now) => _next(now, deletedAt: () => now);

  Task restore(DateTime now) => _next(now, deletedAt: () => null);

  /// Touches [updatedAt]/[version] without changing fields; used when the
  /// task's tag set changes.
  Task touch(DateTime now) => _next(now);
}
