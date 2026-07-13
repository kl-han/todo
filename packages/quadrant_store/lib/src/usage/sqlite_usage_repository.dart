import 'package:quadrant_domain/quadrant_domain.dart' show PlainDate;
import 'package:quadrant_usage/quadrant_usage.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/time_codec.dart';
import 'usage_database.dart';

/// Persistence for raw intervals and daily aggregates in
/// `usage.sqlite3`.
class SqliteUsageRepository {
  SqliteUsageRepository(UsageDatabase database) : _db = database.db;

  final Database _db;

  void insertInterval(UsageInterval interval) {
    _db.execute(
      'INSERT INTO usage_intervals (id, device_id, platform, '
      'application_id, application_name, category_id, started_at, '
      'ended_at, active_seconds, idle_seconds, source, confidence, '
      'window_title) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        interval.id,
        interval.deviceId,
        interval.platform,
        interval.applicationId,
        interval.applicationName,
        interval.categoryId,
        encodeTime(interval.startedAt),
        encodeTime(interval.endedAt),
        interval.activeSeconds,
        interval.idleSeconds,
        interval.source,
        interval.confidence,
        interval.windowTitle,
      ],
    );
  }

  /// Raw intervals started in `[from, to)` (UTC instants), ascending.
  List<UsageInterval> intervalsBetween(DateTime from, DateTime to) {
    final rows = _db.select(
      'SELECT * FROM usage_intervals '
      'WHERE started_at >= ? AND started_at < ? ORDER BY started_at, id',
      [encodeTime(from), encodeTime(to)],
    );
    return [for (final row in rows) _intervalFromRow(row)];
  }

  /// Folds an interval into its daily aggregate row (insert or update).
  void mergeIntoDaily(UsageInterval interval, PlainDate localDate) {
    _db.execute(
      'INSERT INTO usage_daily (date, device_id, application_id, '
      'category_id, active_seconds, idle_seconds, interval_count) '
      'VALUES (?, ?, ?, ?, ?, ?, 1) '
      'ON CONFLICT(date, device_id, application_id) DO UPDATE SET '
      'active_seconds = active_seconds + excluded.active_seconds, '
      'idle_seconds = idle_seconds + excluded.idle_seconds, '
      'interval_count = interval_count + 1',
      [
        localDate.toString(),
        interval.deviceId,
        interval.applicationId,
        interval.categoryId,
        interval.activeSeconds,
        interval.idleSeconds,
      ],
    );
  }

  List<DailyUsage> dailyBetween(PlainDate from, PlainDate to) {
    final rows = _db.select(
      'SELECT * FROM usage_daily WHERE date >= ? AND date <= ? '
      'ORDER BY date, device_id, application_id',
      [from.toString(), to.toString()],
    );
    return [
      for (final row in rows)
        DailyUsage(
          date: PlainDate.parse(row['date'] as String),
          deviceId: row['device_id'] as String,
          applicationId: row['application_id'] as String,
          categoryId: row['category_id'] as String?,
          activeSeconds: row['active_seconds'] as int,
          idleSeconds: row['idle_seconds'] as int,
          focusSessionSeconds: row['focus_session_seconds'] as int,
          intervalCount: row['interval_count'] as int,
        ),
    ];
  }

  /// Deletes raw intervals that started before [cutoff]. Aggregates are
  /// unaffected — retention applies to the sensitive raw level only.
  int pruneIntervalsBefore(DateTime cutoff) {
    _db.execute(
      'DELETE FROM usage_intervals WHERE started_at < ?',
      [encodeTime(cutoff)],
    );
    return _db.updatedRows;
  }

  /// Deletes raw intervals AND aggregates for one local date.
  void deleteDay(PlainDate date, DateTime dayStartUtc, DateTime dayEndUtc) {
    _db.execute(
      'DELETE FROM usage_intervals '
      'WHERE started_at >= ? AND started_at < ?',
      [encodeTime(dayStartUtc), encodeTime(dayEndUtc)],
    );
    _db.execute('DELETE FROM usage_daily WHERE date = ?', [date.toString()]);
  }

  /// Complete deletion: the user can drop all usage history without
  /// touching tasks.
  void deleteAll() {
    _db.execute('DELETE FROM usage_intervals');
    _db.execute('DELETE FROM usage_daily');
  }

  static UsageInterval _intervalFromRow(Row row) => UsageInterval(
        id: row['id'] as String,
        deviceId: row['device_id'] as String,
        platform: row['platform'] as String,
        applicationId: row['application_id'] as String,
        applicationName: row['application_name'] as String,
        categoryId: row['category_id'] as String?,
        startedAt: decodeTime(row['started_at'] as String),
        endedAt: decodeTime(row['ended_at'] as String),
        activeSeconds: row['active_seconds'] as int,
        idleSeconds: row['idle_seconds'] as int,
        source: row['source'] as String,
        confidence: row['confidence'] as String,
        windowTitle: row['window_title'] as String?,
      );
}
