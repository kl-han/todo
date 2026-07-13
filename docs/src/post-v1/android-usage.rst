Android Usage Tracking
======================

Android already maintains application usage history. Use
``UsageStatsManager``; do **not** use an Accessibility Service for
ordinary usage tracking.

``UsageStatsManager`` provides device usage history and requires the
user to grant the special ``PACKAGE_USAGE_STATS`` access.

Workflow
--------

1. Explain exactly what will be collected.
2. Open the system Usage Access settings.
3. The user explicitly enables access.
4. Query events since the last imported timestamp.
5. Convert foreground/resume and background/pause events to intervals.
6. Exclude screen-off and locked periods.
7. Store daily aggregates locally.
8. Use ``WorkManager`` for periodic import.
9. Re-import when the app opens, to cover delayed background work.

``WorkManager`` is appropriate because it persists scheduled work
across process death and reboot, but its execution time is not exact.

Limitations
-----------

* The application cannot guarantee immediate usage-event ingestion.
* Background work may be delayed.
* Users must grant Usage Access in Settings.
* Data precision varies by Android version and vendor.
* Do not run a permanent foreground service merely to query usage
  continuously.
* If the permission is revoked, stop collecting and show a clear
  status.
