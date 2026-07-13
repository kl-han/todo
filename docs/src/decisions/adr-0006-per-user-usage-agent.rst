ADR-0006: Per-User, Event-Driven Desktop Agent
==============================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

Post-v1 adds application-usage tracking, persistent Pomodoro timers,
and reminders that must outlive the GUI window. Three desktop designs
were considered: a privileged system service, a poller that samples the
foreground process on a timer, and a per-user event-driven agent.

A system service is wrong on both platforms: Windows Services run in
Session 0, isolated from the interactive desktop, so they cannot
correctly observe the active user's foreground application; on Linux a
root daemon would hold far more privilege than the job needs. Polling
wastes CPU and battery between the moments anything actually changes.

Decision
--------

Desktops run ``quadrant-agent``, a persistent, event-driven, per-user
process: a ``systemd --user`` service on Linux/Sway and a per-user
login agent on Windows. It runs only inside the logged-in user session,
without root or administrator privilege, and reacts to platform events
(foreground change, idle, lock, suspend) instead of sampling.

The agent never records keystrokes, screenshots, or clipboard contents,
and never monitors raw input devices. It owns desktop reminders and
Pomodoro timers, exposes a loopback-only REST API with a per-install
credential to the Flutter GUI, and becomes the local backend host on
desktop — the GUI no longer owns the SQLite connection or the embedded
server lifecycle there.

Consequences
------------

* Closing the GUI does not cancel a focus session or lose a reminder.
* Idle CPU is effectively zero between events; measurable resource
  targets are defined in :doc:`/post-v1/privacy`.
* No installation step requires administrator access, and no public
  firewall rule is created.
* Fast user switching, lock, and suspend are lifecycle events the agent
  must handle explicitly (see :doc:`/post-v1/test-scenarios`).
* Mobile platforms cannot host such an agent; they follow
  :doc:`adr-0008-os-mediated-mobile-collection` instead.
