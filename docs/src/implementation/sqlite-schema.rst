SQLite Schema
=============

.. versionadded:: 0.2

Schema version 1, created by the first migration in
``packages/quadrant_store/lib/src/migrations/migrations.dart``:

.. code-block:: sql

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

Notes:

* There is **no** stored quadrant or status column — both derive from
  flags and ``completed_at`` (:doc:`/architecture/domain-model`).
* The partial unique index enforces name uniqueness among live tags while
  letting deleted tags free their names.
* Timestamps are fixed-width UTC ISO-8601 strings
  (:doc:`/architecture/persistence-concept`).
