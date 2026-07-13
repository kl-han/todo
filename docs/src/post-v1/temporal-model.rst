Temporal Task Model
===================

Due dates, start dates, reminders, recurrence, and calendar views need a
proper temporal model. Do not add a few nullable timestamps directly and
then build recurrence around them.

Date semantics
--------------

A task can use either:

* **Date-only value** — "due July 20."
* **Zoned local time** — "due July 20 at 3:00 PM America/Chicago."
* **Absolute instant** — the stored UTC time derived from the zoned
  value.

Do not store a date-only deadline as midnight UTC; timezone conversion
can move it to the preceding date.

Task additions
--------------

.. code-block:: text

   Task
   ├── start_kind             none | date | datetime
   ├── start_date
   ├── start_at_utc
   ├── due_kind               none | date | datetime
   ├── due_date
   ├── due_at_utc
   ├── timezone_id
   ├── estimated_minutes
   ├── recurrence_rule_id
   └── needs_review

Behavior
--------

* ``start`` controls when a task becomes actionable or appears on the
  calendar.
* ``due`` represents a deadline.
* Neither field automatically changes the Eisenhower quadrant.
* An optional later policy may *suggest* that an overdue task is urgent,
  but it must not silently modify ``is_urgent``.
