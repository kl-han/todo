import 'package:quadrant_domain/quadrant_domain.dart';

/// Which side of a task's schedule produced an agenda entry.
enum AgendaEntryKind {
  start,
  due;

  String get wireName => name;
}

/// One task appearance on one agenda day.
class AgendaEntry {
  const AgendaEntry({
    required this.kind,
    required this.task,
    this.timeLocal,
  });

  final AgendaEntryKind kind;
  final Task task;

  /// `HH:MM` wall-clock time in the task's timezone; null for date-only
  /// values ("all-day" entries).
  final String? timeLocal;
}

/// All entries for one task-local calendar date.
class AgendaDay {
  const AgendaDay({required this.date, required this.entries});

  final PlainDate date;
  final List<AgendaEntry> entries;
}

/// The agenda read model: days ascending, only days with entries.
class AgendaReport {
  const AgendaReport({
    required this.from,
    required this.to,
    required this.status,
    required this.days,
  });

  final PlainDate from;
  final PlainDate to;
  final String status;
  final List<AgendaDay> days;
}
