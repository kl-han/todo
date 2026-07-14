import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:quadrant_query/quadrant_query.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [TaskRepository].
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  static const _matrixOrder =
      'ORDER BY is_urgent DESC, is_important DESC, updated_at ASC, id ASC';

  @override
  Task? findById(String id) {
    final rows = _db.select('SELECT * FROM tasks WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  List<Task> query(TaskQuery query) {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    switch (query.status) {
      case StatusFilter.open:
        conditions.add('completed_at IS NULL');
      case StatusFilter.completed:
        conditions.add('completed_at IS NOT NULL');
      case StatusFilter.all:
        break;
    }
    if (query.quadrant != null) {
      conditions.add('is_urgent = ? AND is_important = ?');
      args
        ..add(_flag(query.quadrant == Quadrant.q1 || query.quadrant == Quadrant.q3))
        ..add(_flag(query.quadrant == Quadrant.q1 || query.quadrant == Quadrant.q2));
    }
    if (query.tagId != null) {
      conditions.add(
        'id IN (SELECT task_id FROM task_tags WHERE tag_id = ?)',
      );
      args.add(query.tagId);
    }
    final filter = query.filter;
    if (filter != null) {
      final (sql, filterArgs) = _translateFilter(filter);
      conditions.add(sql);
      args.addAll(filterArgs);
    }

    final rows = _db.select(
      'SELECT * FROM tasks WHERE ${conditions.join(' AND ')} $_matrixOrder',
      args,
    );
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  List<Task> scheduled(StatusFilter status) {
    final conditions = <String>[
      'deleted_at IS NULL',
      "(start_kind != 'none' OR due_kind != 'none')",
      switch (status) {
        StatusFilter.open => 'completed_at IS NULL',
        StatusFilter.completed => 'completed_at IS NOT NULL',
        StatusFilter.all => '1 = 1',
      },
    ];
    final rows = _db.select(
      'SELECT * FROM tasks WHERE ${conditions.join(' AND ')}',
    );
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  void insert(Task task) {
    _db.execute(
      'INSERT INTO tasks (id, title, notes, is_urgent, is_important, '
      'start_kind, start_date, start_at_utc, due_kind, due_date, '
      'due_at_utc, timezone_id, estimated_minutes, recurrence_rule_id, '
      'completed_at, created_at, updated_at, deleted_at, version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      _toRow(task),
    );
  }

  @override
  void update(Task task) {
    _db.execute(
      'UPDATE tasks SET title = ?, notes = ?, is_urgent = ?, '
      'is_important = ?, start_kind = ?, start_date = ?, start_at_utc = ?, '
      'due_kind = ?, due_date = ?, due_at_utc = ?, timezone_id = ?, '
      'estimated_minutes = ?, recurrence_rule_id = ?, completed_at = ?, '
      'created_at = ?, updated_at = ?, deleted_at = ?, version = ? '
      'WHERE id = ?',
      [..._toRow(task).sublist(1), task.id],
    );
  }

  @override
  List<String> tagIdsOf(String taskId) {
    final rows = _db.select(
      'SELECT t.id FROM tags t JOIN task_tags tt ON tt.tag_id = t.id '
      'WHERE tt.task_id = ? AND t.deleted_at IS NULL ORDER BY t.name',
      [taskId],
    );
    return [for (final row in rows) row.columnAt(0) as String];
  }

  @override
  bool hasTag(String taskId, String tagId) => _db.select(
        'SELECT 1 FROM task_tags WHERE task_id = ? AND tag_id = ?',
        [taskId, tagId],
      ).isNotEmpty;

  @override
  void assignTag(String taskId, String tagId) {
    _db.execute(
      'INSERT OR IGNORE INTO task_tags (task_id, tag_id) VALUES (?, ?)',
      [taskId, tagId],
    );
  }

  @override
  void removeTag(String taskId, String tagId) {
    _db.execute(
      'DELETE FROM task_tags WHERE task_id = ? AND tag_id = ?',
      [taskId, tagId],
    );
  }

  static int _flag(bool value) => value ? 1 : 0;

  /// Translates a validated filter-rule expression into a SQLite condition
  /// over the `tasks` row plus positional arguments. Membership matches the
  /// reference evaluator: `tag = <name>` is true when the task carries a
  /// non-deleted tag with that exact name.
  static (String, List<Object?>) _translateFilter(FilterExpr expr) {
    switch (expr) {
      case FlagTerm(:final flag):
        final column = flag == TaskFlag.important ? 'is_important' : 'is_urgent';
        return ('$column = 1', const []);
      case TagEquals(:final tagName):
        return (
          'id IN (SELECT tt.task_id FROM task_tags tt '
          'JOIN tags t ON t.id = tt.tag_id '
          'WHERE t.name = ? AND t.deleted_at IS NULL)',
          [tagName],
        );
      case NotExpr(:final operand):
        final (sql, args) = _translateFilter(operand);
        return ('NOT ($sql)', args);
      case AndExpr(:final left, :final right):
        final (leftSql, leftArgs) = _translateFilter(left);
        final (rightSql, rightArgs) = _translateFilter(right);
        return ('($leftSql AND $rightSql)', [...leftArgs, ...rightArgs]);
      case OrExpr(:final left, :final right):
        final (leftSql, leftArgs) = _translateFilter(left);
        final (rightSql, rightArgs) = _translateFilter(right);
        return ('($leftSql OR $rightSql)', [...leftArgs, ...rightArgs]);
    }
  }

  static List<Object?> _toRow(Task task) => [
        task.id,
        task.title,
        task.notes,
        _flag(task.isUrgent),
        _flag(task.isImportant),
        task.schedule.startKind.wireName,
        task.schedule.startDate?.toString(),
        task.schedule.startAtUtc == null
            ? null
            : encodeTime(task.schedule.startAtUtc!),
        task.schedule.dueKind.wireName,
        task.schedule.dueDate?.toString(),
        task.schedule.dueAtUtc == null
            ? null
            : encodeTime(task.schedule.dueAtUtc!),
        task.schedule.timezoneId,
        task.estimatedMinutes,
        task.recurrenceRuleId,
        task.completedAt == null ? null : encodeTime(task.completedAt!),
        encodeTime(task.createdAt),
        encodeTime(task.updatedAt),
        task.deletedAt == null ? null : encodeTime(task.deletedAt!),
        task.version,
      ];

  static Task _fromRow(Row row) => Task(
        id: row['id'] as String,
        title: row['title'] as String,
        notes: row['notes'] as String,
        isUrgent: (row['is_urgent'] as int) != 0,
        isImportant: (row['is_important'] as int) != 0,
        schedule: TaskSchedule(
          startKind: ScheduleKind.fromWire(row['start_kind'] as String),
          startDate: _dateOrNull(row['start_date']),
          startAtUtc: decodeTimeOrNull(row['start_at_utc']),
          dueKind: ScheduleKind.fromWire(row['due_kind'] as String),
          dueDate: _dateOrNull(row['due_date']),
          dueAtUtc: decodeTimeOrNull(row['due_at_utc']),
          timezoneId: row['timezone_id'] as String?,
        ),
        estimatedMinutes: row['estimated_minutes'] as int?,
        recurrenceRuleId: row['recurrence_rule_id'] as String?,
        completedAt: decodeTimeOrNull(row['completed_at']),
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        deletedAt: decodeTimeOrNull(row['deleted_at']),
        version: row['version'] as int,
      );

  static PlainDate? _dateOrNull(Object? value) =>
      value == null ? null : PlainDate.parse(value as String);
}
