Daily Plan
==========

Tables
------

.. code-block:: text

   daily_plans
   ├── id
   ├── local_date
   ├── timezone_id
   ├── planned_minutes
   ├── review_notes
   └── status

   daily_plan_items
   ├── id
   ├── daily_plan_id
   ├── task_id
   ├── occurrence_id
   ├── position
   ├── planned_minutes
   ├── scheduled_start
   └── outcome

Workflow
--------

.. code-block:: text

   Open Daily Plan
   → review overdue tasks
   → select Q1 tasks
   → select limited Q2 work
   → place tasks into time blocks
   → start Pomodoro
   → mark outcomes
   → finish daily review

Do not automatically fill the day with every due task. Provide
suggestions, but keep the user in control.
