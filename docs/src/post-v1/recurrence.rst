Recurring Tasks
===============

Use RFC 5545-style recurrence rules rather than inventing a custom
recurrence language. RFC 5545 (iCalendar) already defines recurrence
rules, date-time values, alarms, start/due properties, and exceptions.

Tables
------

.. code-block:: text

   recurrence_rules
   ├── id
   ├── dtstart
   ├── timezone_id
   ├── rrule
   ├── end_policy
   ├── until_at
   ├── occurrence_count
   ├── created_at
   └── updated_at

   recurrence_exceptions
   ├── recurrence_rule_id
   ├── original_occurrence_at
   ├── exception_type
   └── replacement_occurrence_id

   task_occurrences
   ├── id
   ├── task_id
   ├── recurrence_rule_id
   ├── occurrence_start
   ├── occurrence_due
   ├── status
   ├── completed_at
   └── source_sequence

Occurrences, not resets
-----------------------

Do not repeatedly reset the same task from completed to open; that
destroys history. Instead, each occurrence is its own record:

.. code-block:: text

   Recurring task definition
       ├── Monday occurrence — completed
       ├── Wednesday occurrence — skipped
       └── Friday occurrence — open

Materialize occurrences in a rolling window:

* Past: 30 days.
* Future: 90 days.
* Extend the window whenever the application or the agent runs.

Initial supported patterns
--------------------------

Start with:

* Daily.
* Weekdays.
* Weekly on selected weekdays.
* Monthly by date.
* Monthly by ordinal weekday.
* Every N days/weeks/months.
* End after N occurrences.
* End on a date.
* No end.

Postpone complex calendar rules until the basic engine is proven.
