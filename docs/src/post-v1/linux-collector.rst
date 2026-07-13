Linux/Sway Collector
====================

Use Sway IPC rather than scanning processes or attempting global
Wayland observation. Sway IPC lets clients subscribe to window and
workspace events and retrieve the compositor tree.

Collector behavior
------------------

The ``quadrant-agent`` collector:

1. Connects to ``$SWAYSOCK``.
2. Subscribes to:

   * ``window``
   * ``workspace``
   * ``shutdown``

3. Retrieves the active tree when reconnecting.
4. Reads ``app_id``, PID, and title where available.
5. Records only ``app_id`` by default.
6. Reconnects after a Sway reload.
7. Closes the active interval before logout or suspend.

Idle detection
--------------

Preferred order:

1. Wayland idle-notify protocol adapter.
2. ``systemd-logind`` session ``IdleHint``.
3. Optional ``swayidle`` hooks as a fallback.

Do not monitor raw input devices or ``/dev/input``; that requires
unnecessary privilege and resembles a keylogger.

systemd user service
--------------------

The shipped unit (``devops/agent/systemd/quadrant-agent.service``,
installed by :doc:`/devops/agent-service`):

.. literalinclude:: ../../../devops/agent/systemd/quadrant-agent.service
   :language: ini

The service must run as the normal user, without root privileges.
