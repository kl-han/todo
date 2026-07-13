Database Reference
==================

Schema version: **3** (see :doc:`/implementation/sqlite-schema` for DDL
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

``recurrence_rules``
   ``id`` (uuid PK), ``dtstart`` (plain date), ``rrule`` (canonical
   RFC 5545 subset), timestamps. Rule rows survive detachment so
   settled occurrences keep their history.

   .. versionadded:: 1.2

``task_occurrences``
   ``id`` (uuid PK), ``task_id``/``recurrence_rule_id`` (cascading
   FKs), ``original_date`` (identity; unique per rule), ``kind``
   (``start|due``), ``occurrence_date?`` xor ``occurrence_at_utc?``,
   ``status`` (``open|completed|skipped``), ``completed_at?``,
   timestamps, ``version``.

   .. versionadded:: 1.2

``recurrence_exceptions``
   ``(recurrence_rule_id, original_date)`` composite PK,
   ``exception_type`` (``skipped|rescheduled``), replacement values,
   ``created_at``.

   .. versionadded:: 1.2

``reminders``
   ``id`` (uuid PK), ``task_id?`` xor ``occurrence_id?`` (cascading
   FKs), ``trigger_type``, ``trigger_at_utc?`` xor ``offset_minutes?``,
   ``channel``, ``state``, ``platform_schedule_id?``, timestamps,
   ``version``. Effective triggers are computed on read, never stored.

   .. versionadded:: 1.2

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
