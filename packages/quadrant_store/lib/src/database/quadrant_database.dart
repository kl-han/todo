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

  /// Opens a vault, recovering from an unreadable/corrupt file by moving
  /// it (and its WAL/SHM siblings) aside to `<path>.corrupt-<timestamp>`
  /// and starting fresh. The damaged data is preserved for manual triage;
  /// the app must always be able to boot. Used by the embedded backend —
  /// the standalone server stays strict so an operator notices.
  ///
  /// A database that is *newer* than this build is not corruption and is
  /// still refused (see [migrate]).
  static QuadrantDatabase openWithRecovery(
    String path, {
    void Function(String movedTo)? onCorruptMovedAside,
  }) {
    try {
      final database = open(path);
      // Surface latent page-level corruption now, not mid-session.
      if (!database.integrityOk()) {
        database.close();
        throw const FormatException('integrity_check failed');
      }
      return database;
    } on Object catch (error) {
      if (error is StateError) rethrow; // newer-schema refusal is not corruption
      final suffix =
          '.corrupt-${DateTime.now().toUtc().millisecondsSinceEpoch}';
      final movedTo = '$path$suffix';
      for (final candidate in [path, '$path-wal', '$path-shm']) {
        final file = File(candidate);
        if (file.existsSync()) {
          file.renameSync(candidate == path ? movedTo : '$candidate$suffix');
        }
      }
      onCorruptMovedAside?.call(movedTo);
      return open(path);
    }
  }

  /// SQLite's own page-level check; true when the database is sound.
  bool integrityOk() {
    final result = db.select('PRAGMA integrity_check');
    return result.length == 1 && result.first.columnAt(0) == 'ok';
  }

  /// Verifies a snapshot produced by [backupTo]: the file opens, passes
  /// integrity_check, and is not from a newer build. Returns null when
  /// sound, or a human-readable reason.
  static String? verifySnapshot(String path) {
    if (!File(path).existsSync()) return 'Snapshot does not exist.';
    try {
      final database = open(path);
      try {
        if (!database.integrityOk()) {
          return 'Snapshot fails SQLite integrity_check.';
        }
        return null;
      } finally {
        database.close();
      }
    } on StateError catch (error) {
      return error.message;
    } on Object catch (error) {
      return 'Snapshot cannot be opened: $error';
    }
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

  /// Writes a consistent snapshot of the vault to [destinationPath] using
  /// `VACUUM INTO` — safe while the database is in use, produces a
  /// compact single file, and needs no exclusive lock. Restoration is the
  /// reverse: stop the backend, replace the vault file with the snapshot,
  /// restart.
  void backupTo(String destinationPath) {
    final destination = File(destinationPath);
    Directory(destination.parent.path).createSync(recursive: true);
    if (destination.existsSync()) {
      throw FileSystemException(
        'Backup destination already exists; refusing to overwrite',
        destinationPath,
      );
    }
    db.execute('VACUUM INTO ?', [destinationPath]);
  }

  void close() => db.dispose();
}
