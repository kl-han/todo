ADR-0007: Separate Usage Database
=================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

Usage tracking produces a stream of interval records with a write rate,
sensitivity level, and retention policy entirely unlike task data.
Storing both in one file would couple backup, deletion, and corruption
recovery of private behavioral data to the task vault.

Decision
--------

Usage data lives in its own database, separate from tasks:

.. code-block:: text

   default.sqlite3     Task, recurrence, reminders, plans
   usage.sqlite3       Raw and aggregated usage

Raw intervals are retained briefly (7 days by default, configurable)
and aggregated into ``usage_daily`` rows; only aggregates are retained
long-term, and only aggregates may ever be uploaded remotely — and only
when the user explicitly enables upload.

Consequences
------------

* Usage history can be deleted, expired, or exported without touching
  tasks, and is excluded from normal task backups.
* Corruption or cleanup in the high-churn usage store cannot damage the
  task vault.
* Retention and privacy rules are enforced per database instead of per
  table.
* Reports join the two stores at read time; see
  :doc:`/post-v1/usage-archival`.
