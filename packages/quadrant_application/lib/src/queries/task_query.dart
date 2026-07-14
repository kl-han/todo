import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:quadrant_query/quadrant_query.dart';

/// Status filter for task queries. `all` means open and completed;
/// soft-deleted tasks are never included in query results.
enum StatusFilter {
  open,
  completed,
  all;

  static StatusFilter fromWire(String value) => switch (value) {
        'open' => open,
        'completed' => completed,
        'all' => all,
        _ => throw ArgumentError.value(value, 'status'),
      };
}

/// Sort orders defined by the API contract. `matrixModifiedAsc` is:
/// urgent first, then important, then least-recently-updated, then id.
enum TaskSort {
  matrixModifiedAsc;

  static TaskSort fromWire(String value) => switch (value) {
        'matrix_modified_asc' => matrixModifiedAsc,
        _ => throw ArgumentError.value(value, 'sort'),
      };
}

/// Declarative task query passed through the service to the repository.
class TaskQuery {
  const TaskQuery({
    this.status = StatusFilter.open,
    this.quadrant,
    this.tagId,
    this.filter,
    this.sort = TaskSort.matrixModifiedAsc,
  });

  final StatusFilter status;
  final Quadrant? quadrant;
  final String? tagId;

  /// Optional boolean filter rule over task metadata (importance, urgency,
  /// tags). Parsed and validated by the HTTP layer via [FilterRule]; the
  /// store translates it into SQLite filtering, and its semantics match the
  /// pure reference evaluator. Composes with the other filters (AND) and
  /// with the fixed sort order.
  final FilterExpr? filter;

  final TaskSort sort;
}
