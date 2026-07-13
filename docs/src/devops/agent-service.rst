Agent Service
=============

.. versionadded:: 1.3

``quadrant-agent`` is the per-user desktop agent
(:doc:`/decisions/adr-0006-per-user-usage-agent`): it hosts the local
backend on loopback with a per-install bearer token, owns Pomodoro
timers, and delivers due reminders as desktop notifications. It runs
without root/administrator privilege and binds only to ``127.0.0.1``.

Linux (systemd user service)
----------------------------

The shipped unit: ``devops/agent/systemd/quadrant-agent.service``.

.. literalinclude:: ../../../devops/agent/systemd/quadrant-agent.service
   :language: ini

Install:

.. code-block:: bash

   dart compile exe packages/quadrant_agent/bin/quadrant_agent.dart \
     -o ~/.local/bin/quadrant-agent
   mkdir -p ~/.config/systemd/user
   cp devops/agent/systemd/quadrant-agent.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now quadrant-agent
   quadrant-agent status

On first run the agent creates its credential at
``~/.config/quadrant-todo/agent-token`` (mode 0600) and serves the vault
at ``~/.local/share/quadrant-todo/default.sqlite3``. A file lock in the
config directory guarantees a single instance; the lock dies with the
process, so a crash never wedges the next start.

Reminder delivery uses ``notify-send`` (any XDG notification daemon —
mako, dunst). When no desktop service is reachable, delivery is retried
on the next scheduler tick (every 30 seconds by default; the agent is
idle between ticks).

Windows (per-user logon task)
-----------------------------

Windows Services live in Session 0 and cannot observe the interactive
desktop, so the agent registers as a per-user Task Scheduler entry
instead — no administrator access:

.. code-block:: powershell

   powershell -ExecutionPolicy Bypass `
     -File devops/agent/windows/register-startup-task.ps1

GUI hand-off
------------

While the agent runs, the desktop GUI connects to it as a remote
backend (``http://127.0.0.1:47821`` with the agent token) instead of
opening the vault embedded — one process owns the vault and the timers.
That is what makes "close the window mid-Pomodoro" a non-event.
