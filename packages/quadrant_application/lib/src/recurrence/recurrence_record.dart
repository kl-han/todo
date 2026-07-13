import 'package:quadrant_domain/quadrant_domain.dart';

/// A stored recurrence rule: the parsed rule's canonical RRULE text plus
/// its anchor date. The rule row survives detachment so settled
/// occurrences keep their history.
class RecurrenceRuleRecord {
  const RecurrenceRuleRecord({
    required this.id,
    required this.dtstart,
    required this.rrule,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final PlainDate dtstart;

  /// Canonical RRULE serialization (`RecurrenceRule.toRrule()`).
  final String rrule;

  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Why a generated occurrence deviates from its rule.
enum RecurrenceExceptionType {
  skipped,
  rescheduled;

  String get wireName => name;

  static RecurrenceExceptionType fromWire(String value) => switch (value) {
        'skipped' => skipped,
        'rescheduled' => rescheduled,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown exception type'),
      };
}

/// One recurrence exception, keyed by the occurrence's original date.
class RecurrenceException {
  const RecurrenceException({
    required this.recurrenceRuleId,
    required this.originalDate,
    required this.type,
    required this.createdAt,
    this.replacementDate,
    this.replacementAtUtc,
  });

  final String recurrenceRuleId;
  final PlainDate originalDate;
  final RecurrenceExceptionType type;
  final PlainDate? replacementDate;
  final DateTime? replacementAtUtc;
  final DateTime createdAt;
}

/// Status filter for occurrence queries.
enum OccurrenceFilter {
  open,
  completed,
  skipped,
  all;

  static OccurrenceFilter fromWire(String value) => switch (value) {
        'open' => open,
        'completed' => completed,
        'skipped' => skipped,
        'all' => all,
        _ => throw ArgumentError.value(value, 'status'),
      };

  bool matches(OccurrenceStatus status) => switch (this) {
        open => status == OccurrenceStatus.open,
        completed => status == OccurrenceStatus.completed,
        skipped => status == OccurrenceStatus.skipped,
        all => true,
      };
}
