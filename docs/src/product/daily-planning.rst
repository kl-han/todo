Daily Planning
==============

.. versionadded:: 1.6

A daily plan is the user's deliberate selection of work for one local
date. **Nothing fills it automatically** — overdue and due tasks are
suggestions in the UI at most; what enters the day is always a user
action (:doc:`/post-v1/daily-plan`).

What the user observes:

* Each date has exactly one plan; opening a day materializes an empty
  one. Items are tasks or single occurrences of recurring tasks — the
  same piece of work enters a day once.
* Items carry an order (drag to reorder), an optional time block
  (``HH:MM`` start plus planned minutes), and — at day's end — an
  outcome: ``done``, ``partial``, ``skipped``, or ``moved``.
* The **daily review** closes the loop: record outcomes, write review
  notes, and mark the plan ``reviewed``.
* **Planned versus actual**: the plan's summed minutes against the
  active time of focus sessions started that day — the honest input to
  the weekly review's plan-accuracy section.
* Deleting a task removes it from plans (cascade); history for reviewed
  days keeps its outcomes.

The workflow, end to end:

.. code-block:: text

   Open Daily Plan
   → review overdue tasks
   → select Q1 tasks
   → select limited Q2 work
   → place tasks into time blocks
   → start Pomodoro
   → mark outcomes
   → finish daily review

The calendar presentation over plans, schedules, and occurrences is the
agenda read model (:doc:`/api/agenda-api`); richer week/day views build
on it client-side (:doc:`/post-v1/calendar`).
