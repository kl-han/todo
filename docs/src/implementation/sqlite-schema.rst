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

.. versionchanged:: 1.1

Schema version 2 (second migration) adds the temporal columns to
``tasks``:

.. code-block:: sql

   ALTER TABLE tasks ADD COLUMN start_kind TEXT NOT NULL DEFAULT 'none';
   ALTER TABLE tasks ADD COLUMN start_date TEXT;
   ALTER TABLE tasks ADD COLUMN start_at_utc TEXT;
   ALTER TABLE tasks ADD COLUMN due_kind TEXT NOT NULL DEFAULT 'none';
   ALTER TABLE tasks ADD COLUMN due_date TEXT;
   ALTER TABLE tasks ADD COLUMN due_at_utc TEXT;
   ALTER TABLE tasks ADD COLUMN timezone_id TEXT;
   ALTER TABLE tasks ADD COLUMN estimated_minutes INTEGER;

.. versionchanged:: 1.2

Schema version 3 (third migration) adds ``recurrence_rules``,
``task_occurrences``, ``recurrence_exceptions``, and ``reminders``, plus
``tasks.recurrence_rule_id``; see the migration source and
:doc:`/reference/database-reference` for the exact columns.

.. versionchanged:: 1.3

Schema version 4 (fourth migration) adds ``focus_sessions``; see the
migration source and :doc:`/reference/database-reference`.

Notes:

* There is **no** stored quadrant or status column — both derive from
  flags and ``completed_at`` (:doc:`/architecture/domain-model`).
* ``start_date``/``due_date`` hold plain ``YYYY-MM-DD`` text, never
  midnight-UTC instants (:doc:`/product/scheduling-behavior`).
* The partial unique index enforces name uniqueness among live tags while
  letting deleted tags free their names.
* Timestamps are fixed-width UTC ISO-8601 strings
  (:doc:`/architecture/persistence-concept`).
