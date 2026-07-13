Windows Collector
=================

Use a per-user login process, **not** a Windows Service.

Windows Services run in Session 0, which is isolated from the
interactive user desktop, so a normal service is the wrong place to
observe the active user's foreground application.

APIs
----

Use a small C++ adapter called through Dart FFI:

* ``SetWinEventHook(EVENT_SYSTEM_FOREGROUND, ...)``
* ``GetForegroundWindow``
* ``GetWindowThreadProcessId``
* ``QueryFullProcessImageName``
* ``GetLastInputInfo``
* Session lock/unlock notifications.
* Power suspend/resume notifications.

``SetWinEventHook`` with ``WINEVENT_OUTOFCONTEXT`` provides
asynchronous, ordered event delivery without injecting code into other
processes. ``GetLastInputInfo`` supports idle detection for the current
interactive session.

Startup model
-------------

Recommended order:

1. MSIX Startup Task when packaged.
2. Per-user Task Scheduler entry when using the portable installation.
3. Manual "Start with Windows" preference.

Do not require administrator access.

Acceptance conditions
---------------------

* Works in Windows 10 and 11 user sessions.
* Stops tracking when the session locks.
* Handles fast user switching.
* Handles UAC secure-desktop transitions without crashing.
* Does not report applications from another logged-in user.
* Restarts at login.
* Does not cause a public Windows Firewall rule.
* Tray menu provides Pause, Resume, Private Mode, and Quit.
