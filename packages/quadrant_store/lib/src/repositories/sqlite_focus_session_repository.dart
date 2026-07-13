import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [FocusSessionRepository].
class SqliteFocusSessionRepository implements FocusSessionRepository {
  SqliteFocusSessionRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  @override
  FocusSession? findById(String id) {
    final rows =
        _db.select('SELECT * FROM focus_sessions WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  FocusSession? findActive() {
    final rows = _db.select(
      "SELECT * FROM focus_sessions WHERE phase != 'finished' LIMIT 1",
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  List<FocusSession> list({bool? active, String? taskId}) {
    final conditions = <String>['1 = 1'];
    final args = <Object?>[];
    if (active != null) {
      conditions.add(active ? "phase != 'finished'" : "phase = 'finished'");
    }
    if (taskId != null) {
      conditions.add('task_id = ?');
      args.add(taskId);
    }
    final rows = _db.select(
      'SELECT * FROM focus_sessions WHERE ${conditions.join(' AND ')} '
      'ORDER BY started_at DESC, id ASC',
      args,
    );
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  void insert(FocusSession session) {
    _db.execute(
      'INSERT INTO focus_sessions (id, task_id, occurrence_id, device_id, '
      'planned_focus_seconds, planned_break_seconds, phase, started_at, '
      'ended_at, active_seconds, paused_seconds, last_transition_at, '
      'interruption_count, result, notes, created_at, updated_at, version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      _toRow(session),
    );
  }

  @override
  void update(FocusSession session) {
    _db.execute(
      'UPDATE focus_sessions SET task_id = ?, occurrence_id = ?, '
      'device_id = ?, planned_focus_seconds = ?, planned_break_seconds = ?, '
      'phase = ?, started_at = ?, ended_at = ?, active_seconds = ?, '
      'paused_seconds = ?, last_transition_at = ?, interruption_count = ?, '
      'result = ?, notes = ?, created_at = ?, updated_at = ?, version = ? '
      'WHERE id = ?',
      [..._toRow(session).sublist(1), session.id],
    );
  }

  static List<Object?> _toRow(FocusSession session) => [
        session.id,
        session.taskId,
        session.occurrenceId,
        session.deviceId,
        session.plannedFocusSeconds,
        session.plannedBreakSeconds,
        session.phase.wireName,
        encodeTime(session.startedAt),
        session.endedAt == null ? null : encodeTime(session.endedAt!),
        session.activeSeconds,
        session.pausedSeconds,
        encodeTime(session.lastTransitionAt),
        session.interruptionCount,
        session.result?.wireName,
        session.notes,
        encodeTime(session.createdAt),
        encodeTime(session.updatedAt),
        session.version,
      ];

  static FocusSession _fromRow(Row row) => FocusSession(
        id: row['id'] as String,
        taskId: row['task_id'] as String?,
        occurrenceId: row['occurrence_id'] as String?,
        deviceId: row['device_id'] as String?,
        plannedFocusSeconds: row['planned_focus_seconds'] as int,
        plannedBreakSeconds: row['planned_break_seconds'] as int,
        phase: FocusPhase.fromWire(row['phase'] as String),
        startedAt: decodeTime(row['started_at'] as String),
        endedAt: decodeTimeOrNull(row['ended_at']),
        activeSeconds: row['active_seconds'] as int,
        pausedSeconds: row['paused_seconds'] as int,
        lastTransitionAt: decodeTime(row['last_transition_at'] as String),
        interruptionCount: row['interruption_count'] as int,
        result: row['result'] == null
            ? null
            : FocusResult.fromWire(row['result'] as String),
        notes: row['notes'] as String,
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        version: row['version'] as int,
      );
}
