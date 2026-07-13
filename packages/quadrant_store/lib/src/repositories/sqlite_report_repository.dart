import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [ReportRepository].
class SqliteReportRepository implements ReportRepository {
  SqliteReportRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  @override
  WeeklyReportSnapshot? findSnapshot(PlainDate weekStart) {
    final rows = _db.select(
      'SELECT * FROM weekly_report_snapshots WHERE week_start = ?',
      [weekStart.toString()],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return WeeklyReportSnapshot(
      weekStart: PlainDate.parse(row['week_start'] as String),
      generatedAt: decodeTime(row['generated_at'] as String),
      reportVersion: row['report_version'] as int,
      summaryJson: row['summary_json'] as String,
      userNotes: row['user_notes'] as String,
    );
  }

  @override
  void upsertSnapshot(WeeklyReportSnapshot snapshot) {
    _db.execute(
      'INSERT OR REPLACE INTO weekly_report_snapshots '
      '(week_start, generated_at, report_version, summary_json, '
      'user_notes) VALUES (?, ?, ?, ?, ?)',
      [
        snapshot.weekStart.toString(),
        encodeTime(snapshot.generatedAt),
        snapshot.reportVersion,
        snapshot.summaryJson,
        snapshot.userNotes,
      ],
    );
  }
}
