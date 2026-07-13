Critical Test Scenarios
=======================

Time and recurrence
-------------------

* DST spring-forward missing hour.
* DST fall-back repeated hour.
* User changes timezone.
* Date-only deadline across timezones.
* Monthly recurrence on the 29th, 30th, or 31st.
* Recurrence exception.
* Completing one occurrence without completing the series.

Agent lifecycle
---------------

* Agent crashes while an interval is open.
* Desktop sleeps and resumes.
* User locks and unlocks.
* Windows user switches session.
* Sway reloads.
* Computer clock moves backward.
* GUI closes during Pomodoro.
* Database is temporarily locked.

Android
-------

* Usage Access denied.
* Usage Access revoked.
* ``WorkManager`` delayed for several hours.
* Device reboots.
* Battery optimization restricts the app.
* Usage history returns incomplete events.

Privacy
-------

* Window titles remain null by default.
* An excluded application never enters aggregates.
* Private mode closes the current interval.
* Deleting raw data removes all corresponding rows.
* Remote upload contains aggregates only.
* Disabling tracking prevents collector startup.
