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

  // v2 -> v3: recurrence and reminders (v1.2). Occurrence identity is
  // (rule, original_date); rescheduling moves the value columns, never
  // the identity. Rule rows survive detachment so settled occurrences
  // keep their history.
  '''
  CREATE TABLE recurrence_rules (
    id         TEXT PRIMARY KEY,
    dtstart    TEXT NOT NULL,
    rrule      TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  ALTER TABLE tasks ADD COLUMN recurrence_rule_id TEXT
    REFERENCES recurrence_rules(id);

  CREATE TABLE task_occurrences (
    id                 TEXT PRIMARY KEY,
    task_id            TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    recurrence_rule_id TEXT NOT NULL
      REFERENCES recurrence_rules(id) ON DELETE CASCADE,
    original_date      TEXT NOT NULL,
    kind               TEXT NOT NULL,
    occurrence_date    TEXT,
    occurrence_at_utc  TEXT,
    status             TEXT NOT NULL DEFAULT 'open',
    completed_at       TEXT,
    created_at         TEXT NOT NULL,
    updated_at         TEXT NOT NULL,
    version            INTEGER NOT NULL DEFAULT 1,
    UNIQUE (recurrence_rule_id, original_date)
  );

  CREATE TABLE recurrence_exceptions (
    recurrence_rule_id TEXT NOT NULL
      REFERENCES recurrence_rules(id) ON DELETE CASCADE,
    original_date      TEXT NOT NULL,
    exception_type     TEXT NOT NULL,
    replacement_date   TEXT,
    replacement_at_utc TEXT,
    created_at         TEXT NOT NULL,
    PRIMARY KEY (recurrence_rule_id, original_date)
  );

  CREATE TABLE reminders (
    id                   TEXT PRIMARY KEY,
    task_id              TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    occurrence_id        TEXT
      REFERENCES task_occurrences(id) ON DELETE CASCADE,
    trigger_type         TEXT NOT NULL,
    trigger_at_utc       TEXT,
    offset_minutes       INTEGER,
    channel              TEXT NOT NULL DEFAULT 'notification',
    state                TEXT NOT NULL DEFAULT 'pending',
    platform_schedule_id TEXT,
    created_at           TEXT NOT NULL,
    updated_at           TEXT NOT NULL,
    version              INTEGER NOT NULL DEFAULT 1
  );
  ''',

  // v3 -> v4: focus sessions (v1.3). Durations accumulate at phase
  // transitions; the live portion of the current phase is derived from
  // last_transition_at by clients, never stored.
  '''
  CREATE TABLE focus_sessions (
    id                    TEXT PRIMARY KEY,
    task_id               TEXT REFERENCES tasks(id) ON DELETE SET NULL,
    occurrence_id         TEXT
      REFERENCES task_occurrences(id) ON DELETE SET NULL,
    device_id             TEXT,
    planned_focus_seconds INTEGER NOT NULL,
    planned_break_seconds INTEGER NOT NULL DEFAULT 0,
    phase                 TEXT NOT NULL DEFAULT 'running',
    started_at            TEXT NOT NULL,
    ended_at              TEXT,
    active_seconds        INTEGER NOT NULL DEFAULT 0,
    paused_seconds        INTEGER NOT NULL DEFAULT 0,
    last_transition_at    TEXT NOT NULL,
    interruption_count    INTEGER NOT NULL DEFAULT 0,
    result                TEXT,
    notes                 TEXT NOT NULL DEFAULT '',
    created_at            TEXT NOT NULL,
    updated_at            TEXT NOT NULL,
    version               INTEGER NOT NULL DEFAULT 1
  );
  ''',

  // v4 -> v5: daily plans (v1.6). One plan per local date; items order
  // by position and reference a task xor an occurrence.
  '''
  CREATE TABLE daily_plans (
    id           TEXT PRIMARY KEY,
    local_date   TEXT NOT NULL UNIQUE,
    review_notes TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'open',
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL,
    version      INTEGER NOT NULL DEFAULT 1
  );

  CREATE TABLE daily_plan_items (
    id              TEXT PRIMARY KEY,
    daily_plan_id   TEXT NOT NULL
      REFERENCES daily_plans(id) ON DELETE CASCADE,
    task_id         TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    occurrence_id   TEXT
      REFERENCES task_occurrences(id) ON DELETE CASCADE,
    position        INTEGER NOT NULL,
    planned_minutes INTEGER,
    scheduled_start TEXT,
    outcome         TEXT,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    version         INTEGER NOT NULL DEFAULT 1
  );
  ''',
];

/// Current schema version; reported by `/api/v1/health`.
final int schemaVersion = migrations.length;
