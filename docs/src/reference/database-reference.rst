Database Reference
==================

Schema version: **5** (see :doc:`/implementation/sqlite-schema` for DDL
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

``focus_sessions``
   ``id`` (uuid PK), ``task_id?``/``occurrence_id?`` (SET NULL FKs),
   ``device_id?``, planned focus/break seconds, ``phase``
   (``running|paused|finished``), ``started_at``, ``ended_at?``,
   accumulated ``active_seconds``/``paused_seconds``,
   ``last_transition_at``, ``interruption_count``, ``result?``,
   ``notes``, timestamps, ``version``. Durations accumulate at phase
   transitions; live portions are derived, never stored.

   .. versionadded:: 1.3

``daily_plans`` / ``daily_plan_items``
   One plan per ``local_date`` (unique). Items: ``daily_plan_id``
   (cascade FK), ``task_id?`` xor ``occurrence_id?`` (cascade FKs),
   ``position``, ``planned_minutes?``, ``scheduled_start?`` (``HH:MM``),
   ``outcome?`` (``done|partial|skipped|moved``), timestamps,
   ``version``.

   .. versionadded:: 1.6

usage.sqlite3
-------------

.. versionadded:: 1.4

A separate database (ADR-0007) with its own migration chain
(``usageMigrations``, currently version **1**), its own retention, and
independent deletability:

``usage_intervals``
   Raw spans: ``id``, ``device_id``, ``platform``, ``application_id``,
   ``application_name``, ``category_id?``, ``started_at``/``ended_at``,
   ``active_seconds`` (monotonic), ``idle_seconds``, ``source``,
   ``confidence``, ``window_title?`` (null unless opted in). Pruned
   after the configured raw retention (default 7 days).

``usage_daily``
   ``(date, device_id, application_id)`` composite PK with summed
   ``active_seconds``/``idle_seconds``, ``focus_session_seconds``,
   ``interval_count``. Small, less sensitive, retained long-term; the
   only shape eligible for any future remote upload.

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
