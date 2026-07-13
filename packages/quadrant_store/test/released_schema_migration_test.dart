import 'dart:io';

import 'package:quadrant_store/quadrant_store.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// v1.0 gate: a vault created by EVERY released schema version must
/// migrate to current with its data intact. Each release that changes the
/// schema appends one fixture here — a literal snapshot of the DDL it
/// shipped plus representative data — and this suite proves the upgrade
/// path forever after.
///
/// Fixtures are frozen copies on purpose: they must not track later edits
/// to `migrations.dart`, exactly like a real database in the field.
typedef SchemaFixture = ({
  int version,
  String ddl,
  void Function(Database) seed,
  void Function(Database) verify,
});

final List<SchemaFixture> releasedSchemas = [
  (
    version: 1,
    // Schema v1 exactly as first released in v0.2.0.
    ddl: '''
      CREATE TABLE tasks (
        id           TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        notes        TEXT NOT NULL DEFAULT '',
        is_urgent    INTEGER NOT NULL DEFAULT 0,
        is_important INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        deleted_at   TEXT,
        version      INTEGER NOT NULL DEFAULT 1
      );
      CREATE TABLE tags (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        color      TEXT NOT NULL DEFAULT '#808080',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        version    INTEGER NOT NULL DEFAULT 1
      );
      CREATE UNIQUE INDEX tags_active_name
        ON tags(name) WHERE deleted_at IS NULL;
      CREATE TABLE task_tags (
        task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        tag_id  TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (task_id, tag_id)
      );
      CREATE INDEX tasks_matrix_order
        ON tasks(is_urgent DESC, is_important DESC, updated_at ASC, id ASC)
        WHERE deleted_at IS NULL;
    ''',
    seed: (db) {
      db.execute(
        'INSERT INTO tasks (id, title, created_at, updated_at) VALUES '
        "('11111111-1111-4111-8111-111111111111', 'from schema v1', "
        "'2026-01-01T00:00:00.000000Z', '2026-01-01T00:00:00.000000Z')",
      );
      db.execute(
        'INSERT INTO tags (id, name, created_at, updated_at) VALUES '
        "('22222222-2222-4222-8222-222222222222', 'v1-tag', "
        "'2026-01-01T00:00:00.000000Z', '2026-01-01T00:00:00.000000Z')",
      );
      db.execute(
        'INSERT INTO task_tags (task_id, tag_id) VALUES '
        "('11111111-1111-4111-8111-111111111111', "
        "'22222222-2222-4222-8222-222222222222')",
      );
    },
    verify: (db) {
      expect(
        db.select('SELECT title FROM tasks').map((row) => row['title']),
        ['from schema v1'],
      );
      expect(db.select('SELECT COUNT(*) c FROM task_tags').first['c'], 1);
      // Migration 2 backfills the temporal defaults.
      expect(
        db.select('SELECT start_kind, due_kind FROM tasks').first.values,
        ['none', 'none'],
      );
    },
  ),
  (
    version: 2,
    // Schema v2 exactly as first released in v1.1.0 (temporal columns).
    ddl: '''
      CREATE TABLE tasks (
        id           TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        notes        TEXT NOT NULL DEFAULT '',
        is_urgent    INTEGER NOT NULL DEFAULT 0,
        is_important INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        deleted_at   TEXT,
        version      INTEGER NOT NULL DEFAULT 1,
        start_kind        TEXT NOT NULL DEFAULT 'none',
        start_date        TEXT,
        start_at_utc      TEXT,
        due_kind          TEXT NOT NULL DEFAULT 'none',
        due_date          TEXT,
        due_at_utc        TEXT,
        timezone_id       TEXT,
        estimated_minutes INTEGER
      );
      CREATE TABLE tags (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        color      TEXT NOT NULL DEFAULT '#808080',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        version    INTEGER NOT NULL DEFAULT 1
      );
      CREATE UNIQUE INDEX tags_active_name
        ON tags(name) WHERE deleted_at IS NULL;
      CREATE TABLE task_tags (
        task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        tag_id  TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (task_id, tag_id)
      );
      CREATE INDEX tasks_matrix_order
        ON tasks(is_urgent DESC, is_important DESC, updated_at ASC, id ASC)
        WHERE deleted_at IS NULL;
    ''',
    seed: (db) {
      db.execute(
        'INSERT INTO tasks (id, title, created_at, updated_at, due_kind, '
        'due_date) VALUES '
        "('33333333-3333-4333-8333-333333333333', 'from schema v2', "
        "'2026-07-01T00:00:00.000000Z', '2026-07-01T00:00:00.000000Z', "
        "'date', '2026-07-20')",
      );
    },
    verify: (db) {
      expect(
        db.select('SELECT title, due_kind, due_date FROM tasks').first.values,
        ['from schema v2', 'date', '2026-07-20'],
      );
    },
  ),
];

void main() {
  group('released schema fixtures migrate to current', () {
    for (final fixture in releasedSchemas) {
      test('schema v${fixture.version} → v$schemaVersion with data intact',
          () {
        final dir = Directory.systemTemp.createTempSync('quadrant-mig-');
        addTearDown(() => dir.deleteSync(recursive: true));
        final path = '${dir.path}/vault.sqlite3';

        // Build the old-world database without any current-code help.
        final old = sqlite3.open(path);
        old.execute(fixture.ddl);
        fixture.seed(old);
        old.execute('PRAGMA user_version = ${fixture.version}');
        old.dispose();

        // Opening with the current build must migrate and keep the data.
        final current = QuadrantDatabase.open(path);
        expect(current.userVersion, schemaVersion);
        expect(current.integrityOk(), isTrue);
        fixture.verify(current.db);
        current.close();
      });
    }
  });

  test('every released schema version has a fixture', () {
    // When migrations.length grows, add the fixture for the newly
    // released schema in the same change (add-database-migration skill).
    expect(
      releasedSchemas.map((f) => f.version),
      List.generate(schemaVersion, (index) => index + 1),
      reason: 'a released schema version is missing its migration fixture',
    );
  });
}
