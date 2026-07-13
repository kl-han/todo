import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [PlanningRepository].
class SqlitePlanningRepository implements PlanningRepository {
  SqlitePlanningRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  @override
  DailyPlan? findPlanByDate(PlainDate localDate) {
    final rows = _db.select(
      'SELECT * FROM daily_plans WHERE local_date = ?',
      [localDate.toString()],
    );
    return rows.isEmpty ? null : _planFromRow(rows.first);
  }

  @override
  void insertPlan(DailyPlan plan) {
    _db.execute(
      'INSERT INTO daily_plans (id, local_date, review_notes, status, '
      'created_at, updated_at, version) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        plan.id,
        plan.localDate.toString(),
        plan.reviewNotes,
        plan.status.wireName,
        encodeTime(plan.createdAt),
        encodeTime(plan.updatedAt),
        plan.version,
      ],
    );
  }

  @override
  void updatePlan(DailyPlan plan) {
    _db.execute(
      'UPDATE daily_plans SET review_notes = ?, status = ?, '
      'updated_at = ?, version = ? WHERE id = ?',
      [
        plan.reviewNotes,
        plan.status.wireName,
        encodeTime(plan.updatedAt),
        plan.version,
        plan.id,
      ],
    );
  }

  @override
  DailyPlanItem? findItemById(String id) {
    final rows =
        _db.select('SELECT * FROM daily_plan_items WHERE id = ?', [id]);
    return rows.isEmpty ? null : _itemFromRow(rows.first);
  }

  @override
  List<DailyPlanItem> itemsOf(String planId) {
    final rows = _db.select(
      'SELECT * FROM daily_plan_items WHERE daily_plan_id = ? '
      'ORDER BY position ASC, id ASC',
      [planId],
    );
    return [for (final row in rows) _itemFromRow(row)];
  }

  @override
  void insertItem(DailyPlanItem item) {
    _db.execute(
      'INSERT INTO daily_plan_items (id, daily_plan_id, task_id, '
      'occurrence_id, position, planned_minutes, scheduled_start, '
      'outcome, created_at, updated_at, version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      _itemToRow(item),
    );
  }

  @override
  void updateItem(DailyPlanItem item) {
    _db.execute(
      'UPDATE daily_plan_items SET daily_plan_id = ?, task_id = ?, '
      'occurrence_id = ?, position = ?, planned_minutes = ?, '
      'scheduled_start = ?, outcome = ?, created_at = ?, updated_at = ?, '
      'version = ? WHERE id = ?',
      [..._itemToRow(item).sublist(1), item.id],
    );
  }

  @override
  void deleteItem(String id) {
    _db.execute('DELETE FROM daily_plan_items WHERE id = ?', [id]);
  }

  static DailyPlan _planFromRow(Row row) => DailyPlan(
        id: row['id'] as String,
        localDate: PlainDate.parse(row['local_date'] as String),
        reviewNotes: row['review_notes'] as String,
        status: PlanStatus.fromWire(row['status'] as String),
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        version: row['version'] as int,
      );

  static List<Object?> _itemToRow(DailyPlanItem item) => [
        item.id,
        item.dailyPlanId,
        item.taskId,
        item.occurrenceId,
        item.position,
        item.plannedMinutes,
        item.scheduledStart,
        item.outcome?.wireName,
        encodeTime(item.createdAt),
        encodeTime(item.updatedAt),
        item.version,
      ];

  static DailyPlanItem _itemFromRow(Row row) => DailyPlanItem(
        id: row['id'] as String,
        dailyPlanId: row['daily_plan_id'] as String,
        taskId: row['task_id'] as String?,
        occurrenceId: row['occurrence_id'] as String?,
        position: row['position'] as int,
        plannedMinutes: row['planned_minutes'] as int?,
        scheduledStart: row['scheduled_start'] as String?,
        outcome: row['outcome'] == null
            ? null
            : PlanOutcome.fromWire(row['outcome'] as String),
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        version: row['version'] as int,
      );
}
