Scheduling Behavior
===================

.. versionadded:: 1.1

A task may carry a **start** ("becomes actionable / appears on the
calendar") and a **due** ("deadline") value. Each side is one of:

* **Not scheduled** — the default.
* **A plain date** — "due July 20". No time, no timezone.
* **A date-time** — "due July 20 at 3:00 PM America/Chicago", stored as
  the absolute UTC instant plus the task's IANA ``timezone_id``.

What the user observes:

* A date-only value never shifts: it is stored and transported as a
  plain ``YYYY-MM-DD`` and is never converted through midnight UTC,
  which could move it to the preceding local date.
* A date-time value renders at its wall-clock time in the task's own
  timezone, wherever it is viewed.
* Scheduling **never changes the Eisenhower quadrant**; urgency stays a
  deliberate user decision. (A policy that *suggests* urgency for
  overdue tasks is deliberately deferred; see
  :doc:`/post-v1/temporal-model`.)
* A task may also carry an effort estimate, ``estimated_minutes``
  (1 minute to one week).
* Schedule edits count as modifications: they bump the version and move
  the task in the least-recently-modified ordering.

Agenda
------

The agenda groups scheduled tasks by their **task-local** calendar
date over an inclusive date range (at most 366 days):

* A date-only value appears on its stored date as an all-day entry.
* A date-time value appears on the date of its instant in the task's
  timezone, with its ``HH:MM`` wall-clock time.
* A task with both start and due contributes one entry per side.
* Within a day: all-day entries first, then timed entries by time.

DST boundaries follow the tz database: instants in the spring-forward
gap or the fall-back repeated hour render at their actual local wall
time, on their actual local date.
