Database Reference
==================

Schema version: **1** (see :doc:`/implementation/sqlite-schema` for DDL
and :doc:`/implementation/migrations` for the upgrade policy).

Tables
------

``tasks``
   ``id`` (uuid PK), ``title``, ``notes``, ``is_urgent``,
   ``is_important`` (0/1), ``completed_at?``, ``created_at``,
   ``updated_at``, ``deleted_at?``, ``version``. Status and quadrant are
   derived, never stored.

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
* Soft deletion: ``deleted_at`` set; every query filters
  ``deleted_at IS NULL``.
* Durability: ``journal_mode=WAL``, ``synchronous=FULL``,
  ``foreign_keys=ON`` — set at open, every open.
* ``PRAGMA user_version`` = number of applied migrations; newer-than-
  build databases refuse to open.
* One SQLite file per vault; one serving process per vault.
