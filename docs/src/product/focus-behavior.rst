Focus Sessions
==============

.. versionadded:: 1.3

A focus (Pomodoro) session is a time record, optionally attached to a
task or to one occurrence of a recurring task. **The backend owns the
timer** — on desktop that backend is the :doc:`/devops/agent-service` —
so closing the GUI window never cancels a session; reopening any client
finds it still running.

What the user observes:

* Starting a session starts the timer server-side; at most one session
  is active per vault. Starting a second one is refused.
* A session is ``running``, ``paused``, or ``finished``. Pausing counts
  an interruption; finishing records a result — ``completed``,
  ``cancelled``, or ``interrupted`` — and optional notes.
* Active and paused time accumulate at the transitions. A clock that
  moves backward (NTP correction, timezone play) can never produce
  negative durations — deltas are clamped at zero.
* When the planned focus time is reached, the agent announces it with a
  desktop notification; the session keeps running until the user
  records the result. Nothing is auto-completed.
* Finished sessions feed the daily and weekly reports (v1.6+).

The workflow, end to end:

.. code-block:: text

   Choose task
   → start 25-minute focus session
   → agent starts timer
   → reminder announces completion
   → user records result
   → session contributes to daily and weekly report
