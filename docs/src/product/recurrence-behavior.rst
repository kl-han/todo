Recurrence and Reminders
========================

.. versionadded:: 1.2

Recurring tasks
---------------

A recurring task is a *definition*; each occurrence is its own record
with its own history. Completing Monday's occurrence never reopens,
resets, or touches the task or any sibling occurrence:

.. code-block:: text

   Recurring task definition
       ├── Monday occurrence — completed
       ├── Wednesday occurrence — skipped
       └── Friday occurrence — open

What the user observes:

* Recurrence attaches to a task that has a scheduled **anchor side**
  (its due value, or its start value when no due exists); occurrences
  repeat that side's shape.
* Rules are the RFC 5545 subset (:doc:`/api/recurrence-api`): daily,
  weekdays, weekly on selected weekdays, monthly by date, monthly by
  ordinal weekday, every N days/weeks/months, ending never, after N
  occurrences, or on a date.
* Monthly rules **skip** months that lack the date (the 31st in April,
  Feb 29 outside leap years) — they never clamp to a nearby day.
* Date-time tasks recur at the same *wall-clock time* in the task's
  timezone; the UTC instant of each occurrence shifts across DST
  transitions so 09:30 stays 09:30.
* Occurrences materialize on demand in a rolling window and extend as
  queries reach further; both backends produce identical occurrence
  sets for identical rules.
* Skipping or rescheduling one occurrence records an **exception**
  keyed by the original date: a rescheduled occurrence keeps its
  identity and is never regenerated on its original date.
* Detaching or replacing a rule removes only open occurrences; settled
  (completed/skipped) occurrences are history and survive.

Reminders
---------

A reminder is separate from the task and separate from recurrence. It
is either **absolute** ("at 9:00 on the 18th") or **relative** ("30
minutes before due" / "1 day before start"). Relative reminders require
a date-time side; date-only values take absolute reminders.

The backend stores intent and delivery state
(``pending → scheduled → delivered/dismissed``); platform adapters own
the actual OS notification and record its identifier. The **effective
trigger** is recomputed from the current schedule on every read — never
cached — so after a reboot, restart, or timezone change, recovery is:

1. Query reminders in the scheduling horizon.
2. Reset stale entries to ``pending`` (this discards the recorded
   platform identifier).
3. Reschedule with the platform notifier.
4. Record the new platform identifier.

Moving a task's due date silently moves its relative reminders; no
reminder edit is needed.
