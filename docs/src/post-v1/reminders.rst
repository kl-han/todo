Reminder Architecture
=====================

A reminder is separate from the task and separate from recurrence.

.. code-block:: text

   reminders
   ├── id
   ├── task_id
   ├── occurrence_id
   ├── trigger_type           absolute | relative_start | relative_due
   ├── trigger_at
   ├── offset_minutes
   ├── channel
   ├── state                  pending | scheduled | delivered | dismissed
   ├── platform_schedule_id
   └── updated_at

Examples:

* 30 minutes before start.
* 1 day before due.
* At due time.
* Absolute time independent of start/due.

Delivery adapters
-----------------

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Platform
     - Scheduler
   * - iOS
     - Local notification APIs
   * - Android
     - Alarm/notification adapter; ``WorkManager`` for non-exact
       maintenance
   * - Linux
     - Quadrant Agent plus the desktop notification service
   * - Windows
     - Quadrant Agent plus Windows app notifications

Android exact alarms are restricted and should be requested only when
exact timing is genuinely user-facing. Most task reminders tolerate
small delays; maintenance and rescheduling belong in ``WorkManager``.

Reminder recovery
-----------------

On launch, reboot, agent restart, or timezone change:

1. Query reminders in the scheduling horizon.
2. Remove stale platform schedule identifiers.
3. Recalculate recurrence occurrences.
4. Reschedule pending reminders.
5. Record the new platform identifier.
6. Prevent duplicate delivery with an idempotency key.
