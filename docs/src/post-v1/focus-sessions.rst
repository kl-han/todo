Pomodoro Focus Sessions
=======================

A Pomodoro session is a time record associated with a task or an
occurrence.

.. code-block:: text

   focus_sessions
   ├── id
   ├── task_id
   ├── occurrence_id
   ├── device_id
   ├── planned_focus_seconds
   ├── planned_break_seconds
   ├── started_at
   ├── ended_at
   ├── active_seconds
   ├── paused_seconds
   ├── interruption_count
   ├── result                 completed | cancelled | interrupted
   └── notes

Workflow
--------

.. code-block:: text

   Choose task
   → start 25-minute focus session
   → agent starts timer
   → desktop usage collector observes active applications
   → reminder announces completion
   → user records result
   → session contributes to daily and weekly report

Ownership
---------

The agent, not the desktop GUI, owns an active Pomodoro timer. Closing
the window must not cancel the session.

On Android, a Pomodoro that must run continuously uses a foreground
service with a visible notification — and only while the timer is
active. Android's long-running background work mechanisms require
user-visible treatment and are subject to job quotas.
