import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Ordered migrations for `usage.sqlite3` — deliberately a separate
/// database from the task vault (ADR-0007): higher write rate, its own
/// retention and privacy rules, excluded from task backups, and
/// deletable without touching tasks.
const List<String> usageMigrations = [
  // v0 -> v1: raw intervals and daily aggregates.
  '''
  CREATE TABLE usage_intervals (
    id               TEXT PRIMARY KEY,
    device_id        TEXT NOT NULL,
    platform         TEXT NOT NULL,
    application_id   TEXT NOT NULL,
    application_name TEXT NOT NULL DEFAULT '',
    category_id      TEXT,
    started_at       TEXT NOT NULL,
    ended_at         TEXT NOT NULL,
    active_seconds   INTEGER NOT NULL,
    idle_seconds     INTEGER NOT NULL DEFAULT 0,
    source           TEXT NOT NULL,
    confidence       TEXT NOT NULL DEFAULT 'exact',
    window_title     TEXT
  );

  CREATE INDEX usage_intervals_started ON usage_intervals(started_at);

  CREATE TABLE usage_daily (
    date                  TEXT NOT NULL,
    device_id             TEXT NOT NULL,
    application_id        TEXT NOT NULL,
    category_id           TEXT,
    active_seconds        INTEGER NOT NULL DEFAULT 0,
    idle_seconds          INTEGER NOT NULL DEFAULT 0,
    focus_session_seconds INTEGER NOT NULL DEFAULT 0,
    interval_count        INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (date, device_id, application_id)
  );
  ''',
];

/// Current usage schema version.
final int usageSchemaVersion = usageMigrations.length;

/// The usage store: one `usage.sqlite3` per device, opened with the same
/// durability settings as the vault.
class UsageDatabase {
  UsageDatabase._(this.db, this.path);

  final Database db;
  final String? path;

  static UsageDatabase open(String path) {
    Directory(File(path).parent.path).createSync(recursive: true);
    return UsageDatabase._(sqlite3.open(path), path).._configure();
  }

  static UsageDatabase inMemory() =>
      UsageDatabase._(sqlite3.openInMemory(), null).._configure();

  void _configure() {
    db
      ..execute('PRAGMA foreign_keys = ON')
      ..execute('PRAGMA journal_mode = WAL')
      ..execute('PRAGMA synchronous = FULL');
    var version =
        db.select('PRAGMA user_version').first.columnAt(0) as int;
    if (version > usageMigrations.length) {
      throw StateError(
        'Usage schema version $version is newer than this build '
        '(${usageMigrations.length}); refusing to open.',
      );
    }
    while (version < usageMigrations.length) {
      db.execute('BEGIN');
      try {
        db.execute(usageMigrations[version]);
        version += 1;
        db.execute('PRAGMA user_version = $version');
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  void close() => db.dispose();
}
