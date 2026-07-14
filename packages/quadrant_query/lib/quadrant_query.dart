/// The boolean filter-rule expression language for Quadrant Todo.
///
/// Users define named rules as boolean expressions over task metadata and
/// apply them to task views. This package is the shared, pure definition of
/// that language: it lexes, parses, and validates a rule, and evaluates the
/// parsed rule against task facts. The evaluator is the *reference*
/// semantics — the application and backend layers translate a validated
/// rule into backend/SQLite filtering, which must match this package
/// (rules are never evaluated in widget logic).
///
/// See `docs/src/product/sorting-filtering.rst`.
library;

export 'src/filter_rule.dart';
export 'src/task_facts.dart';
