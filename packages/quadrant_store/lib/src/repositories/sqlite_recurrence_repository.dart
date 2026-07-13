import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [RecurrenceRepository].
class SqliteRecurrenceRepository implements RecurrenceRepository {
  SqliteRecurrenceRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  @override
  RecurrenceRuleRecord? findRuleById(String id) {
    final rows =
        _db.select('SELECT * FROM recurrence_rules WHERE id = ?', [id]);
    return rows.isEmpty ? null : _ruleFromRow(rows.first);
  }

  @override
  void insertRule(RecurrenceRuleRecord rule) {
    _db.execute(
      'INSERT INTO recurrence_rules '
      '(id, dtstart, rrule, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
      [
        rule.id,
        rule.dtstart.toString(),
        rule.rrule,
        encodeTime(rule.createdAt),
        encodeTime(rule.updatedAt),
      ],
    );
  }

  @override
  List<({RecurrenceRuleRecord rule, String taskId})> activeRuleBindings() {
    final rows = _db.select(
      'SELECT r.*, t.id AS bound_task_id FROM recurrence_rules r '
      'JOIN tasks t ON t.recurrence_rule_id = r.id '
      'WHERE t.deleted_at IS NULL',
    );
    return [
      for (final row in rows)
        (rule: _ruleFromRow(row), taskId: row['bound_task_id'] as String),
    ];
  }

  @override
  TaskOccurrence? findOccurrenceById(String id) {
    final rows =
        _db.select('SELECT * FROM task_occurrences WHERE id = ?', [id]);
    return rows.isEmpty ? null : _occurrenceFromRow(rows.first);
  }

  @override
  Set<PlainDate> materializedDates(String ruleId) {
    final rows = _db.select(
      'SELECT original_date FROM task_occurrences '
      'WHERE recurrence_rule_id = ?',
      [ruleId],
    );
    return {
      for (final row in rows) PlainDate.parse(row.columnAt(0) as String),
    };
  }

  @override
  List<TaskOccurrence> occurrencesBetween(
    PlainDate from,
    PlainDate to, {
    OccurrenceFilter status = OccurrenceFilter.all,
    String? taskId,
  }) {
    final conditions = ['original_date >= ?', 'original_date <= ?'];
    final args = <Object?>[from.toString(), to.toString()];
    if (status != OccurrenceFilter.all) {
      conditions.add('status = ?');
      args.add(status.name);
    }
    if (taskId != null) {
      conditions.add('task_id = ?');
      args.add(taskId);
    }
    final rows = _db.select(
      'SELECT * FROM task_occurrences WHERE ${conditions.join(' AND ')} '
      'ORDER BY original_date ASC, id ASC',
      args,
    );
    return [for (final row in rows) _occurrenceFromRow(row)];
  }

  @override
  void insertOccurrence(TaskOccurrence occurrence) {
    _db.execute(
      'INSERT INTO task_occurrences (id, task_id, recurrence_rule_id, '
      'original_date, kind, occurrence_date, occurrence_at_utc, status, '
      'completed_at, created_at, updated_at, version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      _occurrenceToRow(occurrence),
    );
  }

  @override
  void updateOccurrence(TaskOccurrence occurrence) {
    _db.execute(
      'UPDATE task_occurrences SET task_id = ?, recurrence_rule_id = ?, '
      'original_date = ?, kind = ?, occurrence_date = ?, '
      'occurrence_at_utc = ?, status = ?, completed_at = ?, '
      'created_at = ?, updated_at = ?, version = ? WHERE id = ?',
      [..._occurrenceToRow(occurrence).sublist(1), occurrence.id],
    );
  }

  @override
  void deleteOpenOccurrences(String ruleId) {
    _db.execute(
      'DELETE FROM task_occurrences '
      "WHERE recurrence_rule_id = ? AND status = 'open'",
      [ruleId],
    );
  }

  @override
  RecurrenceException? findException(String ruleId, PlainDate originalDate) {
    final rows = _db.select(
      'SELECT * FROM recurrence_exceptions '
      'WHERE recurrence_rule_id = ? AND original_date = ?',
      [ruleId, originalDate.toString()],
    );
    return rows.isEmpty ? null : _exceptionFromRow(rows.first);
  }

  @override
  void upsertException(RecurrenceException exception) {
    _db.execute(
      'INSERT OR REPLACE INTO recurrence_exceptions (recurrence_rule_id, '
      'original_date, exception_type, replacement_date, '
      'replacement_at_utc, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        exception.recurrenceRuleId,
        exception.originalDate.toString(),
        exception.type.wireName,
        exception.replacementDate?.toString(),
        exception.replacementAtUtc == null
            ? null
            : encodeTime(exception.replacementAtUtc!),
        encodeTime(exception.createdAt),
      ],
    );
  }

  @override
  void deleteException(String ruleId, PlainDate originalDate) {
    _db.execute(
      'DELETE FROM recurrence_exceptions '
      'WHERE recurrence_rule_id = ? AND original_date = ?',
      [ruleId, originalDate.toString()],
    );
  }

  static RecurrenceRuleRecord _ruleFromRow(Row row) => RecurrenceRuleRecord(
        id: row['id'] as String,
        dtstart: PlainDate.parse(row['dtstart'] as String),
        rrule: row['rrule'] as String,
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
      );

  static List<Object?> _occurrenceToRow(TaskOccurrence occurrence) => [
        occurrence.id,
        occurrence.taskId,
        occurrence.recurrenceRuleId,
        occurrence.originalDate.toString(),
        occurrence.kind.wireName,
        occurrence.date?.toString(),
        occurrence.atUtc == null ? null : encodeTime(occurrence.atUtc!),
        occurrence.status.wireName,
        occurrence.completedAt == null
            ? null
            : encodeTime(occurrence.completedAt!),
        encodeTime(occurrence.createdAt),
        encodeTime(occurrence.updatedAt),
        occurrence.version,
      ];

  static TaskOccurrence _occurrenceFromRow(Row row) => TaskOccurrence(
        id: row['id'] as String,
        taskId: row['task_id'] as String,
        recurrenceRuleId: row['recurrence_rule_id'] as String,
        originalDate: PlainDate.parse(row['original_date'] as String),
        kind: OccurrenceKind.fromWire(row['kind'] as String),
        date: row['occurrence_date'] == null
            ? null
            : PlainDate.parse(row['occurrence_date'] as String),
        atUtc: decodeTimeOrNull(row['occurrence_at_utc']),
        status: OccurrenceStatus.fromWire(row['status'] as String),
        completedAt: decodeTimeOrNull(row['completed_at']),
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        version: row['version'] as int,
      );

  static RecurrenceException _exceptionFromRow(Row row) => RecurrenceException(
        recurrenceRuleId: row['recurrence_rule_id'] as String,
        originalDate: PlainDate.parse(row['original_date'] as String),
        type: RecurrenceExceptionType.fromWire(
            row['exception_type'] as String),
        replacementDate: row['replacement_date'] == null
            ? null
            : PlainDate.parse(row['replacement_date'] as String),
        replacementAtUtc: decodeTimeOrNull(row['replacement_at_utc']),
        createdAt: decodeTime(row['created_at'] as String),
      );
}
