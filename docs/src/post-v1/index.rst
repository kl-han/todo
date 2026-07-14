Post-v1 Design
==============

.. note::

   Everything in this section is design for the post-v1 milestones
   (v1.1 through v2.0). None of it is implemented in v1.0, and none of
   it changes v1.0 behavior. Each milestone lands with its own
   migrations, tests, and page updates in the normative sections.

Post-v1 extends Quadrant Todo from a task manager into a personal
planning product: start and due dates, recurrence, reminders, Pomodoro
focus sessions, application-usage tracking, daily planning, calendar
presentation, and a weekly review report.

Central decision
----------------

The central architectural decision (recorded in
:doc:`/decisions/adr-0006-per-user-usage-agent`,
:doc:`/decisions/adr-0007-separate-usage-database`, and
:doc:`/decisions/adr-0008-os-mediated-mobile-collection`) is:

* **Desktops** run a persistent, event-driven, per-user Quadrant Agent —
  not a privileged system service, and not a poller.
* **Mobile** uses OS-mediated, scheduled collection — Android via
  ``UsageStatsManager`` plus scheduled background work; iOS offers no
  general usage daemon at all.
* **Usage data** lives in its own high-churn database
  (``usage.sqlite3``), separate from tasks.
* **Reporting and any remote transfer** operate on privacy-preserving
  daily aggregates, never raw intervals.

The desktop agent:

* runs only in the logged-in user session, without root or
  administrator privilege;
* tracks foreground-application changes, lock/suspend, and idle state
  through platform events;
* never records keystrokes, screenshots, or clipboard contents;
* retains detailed intervals briefly, then aggregates them by day;
* owns desktop reminders and Pomodoro timers, so both continue when the
  GUI is closed;
* exposes a loopback REST API to the Flutter GUI;
* uploads only aggregate usage data remotely, and only when explicitly
  enabled.

Target architecture
-------------------

.. code-block:: text

   ┌─────────────────────────────┐
   │         Flutter GUI         │
   └──────────────┬──────────────┘
                  │ loopback REST
   ┌──────────────▼──────────────┐
   │     Local backend host      │
   │      (quadrant-agent)       │
   └───┬──────────┬──────────┬───┘
       │          │          │
       ▼          ▼          ▼
   ┌────────┐ ┌────────┐ ┌───────────┐
   │ Task   │ │Reminder│ │ Platform  │
   │ API    │ │and     │ │ usage     │
   │ (local │ │Pomodoro│ │ collector │
   │ or     │ │schedul-│ └─────┬─────┘
   │ remote)│ │er      │       │
   └───┬────┘ └────────┘       ▼
       │                ┌───────────────┐
       ▼                │ usage.sqlite3 │
   task vault or        └───────┬───────┘
   remote server                │
       │                        │
       └───────────┬────────────┘
                   ▼
        daily and weekly analytics

On desktop, the agent becomes the local backend host: the GUI no longer
owns the SQLite connection or the embedded server lifecycle. On mobile,
the application keeps its embedded backend, because those operating
systems do not allow a normal, unrestricted, permanent daemon.

Runtime by platform
-------------------

.. list-table::
   :header-rows: 1
   :widths: 16 42 42

   * - Platform
     - Persistent component
     - Usage collection
   * - Linux/Sway
     - ``quadrant-agent`` as a ``systemd --user`` service
     - Sway IPC events and an idle adapter
   * - Windows
     - Per-user login agent
     - Win32 foreground-window events and the idle API
   * - Android
     - OS-managed scheduled worker
     - ``UsageStatsManager``
   * - iOS
     - No general daemon
     - Screen Time APIs if the entitlement is available; otherwise
       app-only tracking

Contents
--------

.. toctree::
   :maxdepth: 2

   temporal-model
   recurrence
   reminders
   focus-sessions
   usage-tracking
   windows-collector
   linux-collector
   android-usage
   ios-limitations
   privacy
   usage-archival
   daily-plan
   calendar
   weekly-review
   api-additions
   package-structure
   web-platform-plan
   milestones
   test-scenarios
