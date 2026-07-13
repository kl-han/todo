Database Reference
==================

Schema version: **2** (see :doc:`/implementation/sqlite-schema` for DDL
and :doc:`/implementation/migrations` for the upgrade policy).

Tables
------

``tasks``
   ``id`` (uuid PK), ``title``, ``notes``, ``is_urgent``,
   ``is_important`` (0/1), ``completed_at?``, ``created_at``,
   ``updated_at``, ``deleted_at?``, ``version``. Status and quadrant are
   derived, never stored.

   .. versionchanged:: 1.1
      Schema v2 adds the temporal columns: ``start_kind``/``due_kind``
      (``none|date|datetime``, default ``none``), ``start_date?``/
      ``due_date?`` (plain ``YYYY-MM-DD`` text), ``start_at_utc?``/
      ``due_at_utc?`` (instants), ``timezone_id?`` (IANA id), and
      ``estimated_minutes?``.

``tags``
   ``id`` (uuid PK), ``name`` (unique among rows with
   ``deleted_at IS NULL``), ``color`` (``#rrggbb``), timestamps,
   ``deleted_at?``, ``version``.

``task_tags``
   ``(task_id, tag_id)`` composite PK, both cascading FKs.

Conventions
-----------

* Timestamps: fixed-width UTC ISO-8601 with microseconds
  (``2026-01-02T03:04:05.000006Z``) so string order equals time order.
* Date-only schedule values are plain ``YYYY-MM-DD`` text — never
  midnight-UTC instants, which timezone conversion could shift to the
  preceding date.
* Soft deletion: ``deleted_at`` set; every query filters
  ``deleted_at IS NULL``.
* Durability: ``journal_mode=WAL``, ``synchronous=FULL``,
  ``foreign_keys=ON`` — set at open, every open.
* ``PRAGMA user_version`` = number of applied migrations; newer-than-
  build databases refuse to open.
* One SQLite file per vault; one serving process per vault.
