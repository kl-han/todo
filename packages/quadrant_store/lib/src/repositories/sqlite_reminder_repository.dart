import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [ReminderRepository].
class SqliteReminderRepository implements ReminderRepository {
  SqliteReminderRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  @override
  Reminder? findById(String id) {
    final rows = _db.select('SELECT * FROM reminders WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  List<Reminder> list() {
    final rows = _db.select('SELECT * FROM reminders ORDER BY id');
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  void insert(Reminder reminder) {
    _db.execute(
      'INSERT INTO reminders (id, task_id, occurrence_id, trigger_type, '
      'trigger_at_utc, offset_minutes, channel, state, '
      'platform_schedule_id, created_at, updated_at, version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      _toRow(reminder),
    );
  }

  @override
  void update(Reminder reminder) {
    _db.execute(
      'UPDATE reminders SET task_id = ?, occurrence_id = ?, '
      'trigger_type = ?, trigger_at_utc = ?, offset_minutes = ?, '
      'channel = ?, state = ?, platform_schedule_id = ?, created_at = ?, '
      'updated_at = ?, version = ? WHERE id = ?',
      [..._toRow(reminder).sublist(1), reminder.id],
    );
  }

  @override
  void delete(String id) {
    _db.execute('DELETE FROM reminders WHERE id = ?', [id]);
  }

  static List<Object?> _toRow(Reminder reminder) => [
        reminder.id,
        reminder.taskId,
        reminder.occurrenceId,
        reminder.trigger.wireName,
        reminder.triggerAtUtc == null
            ? null
            : encodeTime(reminder.triggerAtUtc!),
        reminder.offsetMinutes,
        reminder.channel,
        reminder.state.wireName,
        reminder.platformScheduleId,
        encodeTime(reminder.createdAt),
        encodeTime(reminder.updatedAt),
        reminder.version,
      ];

  static Reminder _fromRow(Row row) => Reminder(
        id: row['id'] as String,
        taskId: row['task_id'] as String?,
        occurrenceId: row['occurrence_id'] as String?,
        trigger: ReminderTrigger.fromWire(row['trigger_type'] as String),
        triggerAtUtc: decodeTimeOrNull(row['trigger_at_utc']),
        offsetMinutes: row['offset_minutes'] as int?,
        channel: row['channel'] as String,
        state: ReminderState.fromWire(row['state'] as String),
        platformScheduleId: row['platform_schedule_id'] as String?,
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        version: row['version'] as int,
      );
}
