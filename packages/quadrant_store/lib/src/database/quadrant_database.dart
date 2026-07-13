import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../migrations/migrations.dart';

/// One vault: one SQLite database file (or an in-memory database for
/// tests). Opening migrates to the current schema and configures the
/// durability settings the REST contract depends on (a write that got a
/// 2xx response has been committed).
class QuadrantDatabase {
  QuadrantDatabase._(this.db, this.path);

  /// The underlying connection; owned by the backend that opened it.
  final Database db;

  /// File path, or null for in-memory.
  final String? path;

  static QuadrantDatabase open(String path) {
    Directory(File(path).parent.path).createSync(recursive: true);
    final db = sqlite3.open(path);
    return QuadrantDatabase._(db, path).._configure();
  }

  static QuadrantDatabase inMemory() =>
      QuadrantDatabase._(sqlite3.openInMemory(), null).._configure();

  void _configure() {
    db
      ..execute('PRAGMA foreign_keys = ON')
      ..execute('PRAGMA journal_mode = WAL')
      // Full sync: commits are durable when reported, matching the API
      // guarantee that a 2xx write survives process death.
      ..execute('PRAGMA synchronous = FULL');
    migrate();
  }

  int get userVersion =>
      db.select('PRAGMA user_version').first.columnAt(0) as int;

  void migrate() {
    var version = userVersion;
    if (version > migrations.length) {
      throw StateError(
        'Database schema version $version is newer than this build '
        '(${migrations.length}); refusing to open.',
      );
    }
    while (version < migrations.length) {
      db.execute('BEGIN');
      try {
        db.execute(migrations[version]);
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
