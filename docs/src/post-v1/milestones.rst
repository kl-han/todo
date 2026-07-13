Implementation Roadmap
======================

v1.1 — Temporal foundation
--------------------------

Implement:

* Start date.
* Due date.
* Date-only versus date-time values.
* Timezone behavior.
* Agenda view.
* API and database migration.
* DST and timezone tests.

**Build goal:** all four clients can create and display equivalent
start/due values.

v1.2 — Recurrence and reminders
-------------------------------

Implement:

* RFC-style recurrence rules.
* Occurrence materialization.
* Exceptions.
* Reminder records.
* iOS, Android, Linux, and Windows notification adapters.
* Reboot/resume rescheduling.

**Build goal:** a recurring task produces the same occurrences on every
platform.

v1.3 — Pomodoro and desktop agent
---------------------------------

Implement:

* Focus sessions.
* Persistent desktop timer.
* ``quadrant-agent``.
* Windows login startup.
* Linux systemd user service.
* Desktop notifications.
* Pause/resume/recovery.

**Build goal:** closing the desktop GUI does not stop an active focus
session.

v1.4 — Windows and Sway usage collection
----------------------------------------

Implement:

* Windows WinEvent collector.
* Windows idle collector.
* Sway IPC collector.
* Linux idle collector.
* Lock/suspend handling.
* ``usage.sqlite3``.
* Privacy controls.
* Daily aggregation.

**Build goal:** application intervals are accurate without polling
every second.

v1.5 — Android usage integration
--------------------------------

Implement:

* Usage Access onboarding.
* ``UsageStatsManager`` importer.
* ``WorkManager`` scheduled import.
* Permission-revocation behavior.
* Android usage reports.

Also conduct the iOS ``DeviceActivity`` entitlement feasibility spike.

v1.6 — Daily planning and calendar
----------------------------------

Implement:

* Daily plan.
* Agenda/week/day presentation.
* Task scheduling.
* Pomodoro launch from plan.
* Planned-versus-actual calculation.

v1.7 — Weekly review
--------------------

Implement:

* Cross-device daily aggregate queries.
* Weekly report.
* Category mappings.
* Q2 time analysis.
* Carryover and stale-task review.
* Export to JSON/CSV.

v2.0 — Integrated personal planning release
-------------------------------------------

Acceptance requires:

* Correct temporal behavior across timezones and DST.
* Reliable recurrence exceptions.
* Reminders after reboot.
* Persistent desktop Pomodoro.
* Low-intrusion Windows/Sway tracking.
* Android usage reporting.
* Explicit iOS capability limitations.
* Configurable retention and complete deletion.
* Daily planning and weekly reports.
* No raw input, screenshot, or clipboard collection.
