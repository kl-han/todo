Usage Data Archival
===================

Usage history retention uses a two-level model: short-lived raw
intervals and long-lived daily aggregates.

Raw data
--------

Raw intervals are stored in ``usage.sqlite3``.

Retention:

* Default: 7 days.
* Configurable: 1, 7, 30, or 90 days.
* Never upload raw window-level data by default.

Daily aggregates
----------------

.. code-block:: text

   usage_daily
   ├── date
   ├── device_id
   ├── application_id
   ├── category_id
   ├── active_seconds
   ├── idle_seconds
   ├── focus_session_seconds
   └── interval_count

Daily aggregates can be retained long-term because they are smaller and
less sensitive.

Weekly report snapshots
-----------------------

Weekly reports are normally computed on demand. Store a snapshot only
when the user finalizes or annotates a report:

.. code-block:: text

   weekly_report_snapshots
   ├── week_start
   ├── generated_at
   ├── report_version
   ├── summary_json
   └── user_notes

Separate databases
------------------

.. code-block:: text

   default.sqlite3     Task, recurrence, reminders, plans
   usage.sqlite3       Raw and aggregated usage

Reasons (see :doc:`/decisions/adr-0007-separate-usage-database`):

* Usage has a higher write rate.
* Usage data has different retention and privacy rules.
* It can be excluded from normal task backups.
* Corruption or cleanup in usage history does not risk tasks.
* The user can delete usage history without touching tasks.
