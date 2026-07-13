/// Ordered schema migrations. `user_version` of the database equals the
/// index of the last applied migration + 1; migration N upgrades a
/// database at version N to N+1. Migrations are append-only — released
/// migrations are never edited (v1.0 requires every released schema to
/// migrate cleanly to current).
const List<String> migrations = [
  // v0 -> v1: initial task/tag schema.
  '''
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

  // v1 -> v2: temporal foundation (v1.1). Date-only values are stored as
  // plain YYYY-MM-DD text, never as midnight-UTC instants; instants use
  // the fixed-width UTC codec shared with the other timestamp columns.
  '''
  ALTER TABLE tasks ADD COLUMN start_kind TEXT NOT NULL DEFAULT 'none';
  ALTER TABLE tasks ADD COLUMN start_date TEXT;
  ALTER TABLE tasks ADD COLUMN start_at_utc TEXT;
  ALTER TABLE tasks ADD COLUMN due_kind TEXT NOT NULL DEFAULT 'none';
  ALTER TABLE tasks ADD COLUMN due_date TEXT;
  ALTER TABLE tasks ADD COLUMN due_at_utc TEXT;
  ALTER TABLE tasks ADD COLUMN timezone_id TEXT;
  ALTER TABLE tasks ADD COLUMN estimated_minutes INTEGER;
  ''',
];

/// Current schema version; reported by `/api/v1/health`.
final int schemaVersion = migrations.length;
