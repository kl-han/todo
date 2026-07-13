Desktop Usage Tracking
======================

What to collect
---------------

The default record:

.. code-block:: text

   usage_intervals
   ├── id
   ├── device_id
   ├── platform
   ├── application_id
   ├── application_name
   ├── category_id
   ├── started_at
   ├── ended_at
   ├── active_seconds
   ├── idle_seconds
   ├── source
   ├── confidence
   └── window_title           null by default

Do **not** collect by default:

* Keystrokes.
* Mouse coordinates.
* Screenshots.
* Clipboard contents.
* Document contents.
* Browser URLs.
* Window titles.

Window titles often contain document names, search terms, email
subjects, or private messages. They are a separate, explicit opt-in
setting with configurable redaction.

Event processing
----------------

Do not sample the foreground process every second. Use this state
machine:

.. code-block:: text

   Foreground application changes
   → close previous interval
   → open new interval

   User becomes idle
   → close active interval at idle threshold
   → enter idle state

   User resumes
   → open new interval

   Screen locks/suspends
   → close active interval

   Agent restarts
   → recover or discard incomplete interval safely

Store both:

* the wall-clock timestamp, for calendar reporting; and
* monotonic elapsed time, for duration calculation.

This prevents clock changes or network time correction from producing
negative durations.
