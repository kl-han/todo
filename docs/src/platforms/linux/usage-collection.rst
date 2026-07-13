Usage Collection (Sway)
=======================

.. versionadded:: 1.4

The agent's Linux collector speaks the i3/Sway IPC protocol directly
over ``$SWAYSOCK`` — no process scanning, no polling, no global Wayland
observation (see :doc:`/post-v1/linux-collector` for the design):

1. Connect and ``SUBSCRIBE`` to ``window`` and ``shutdown`` events.
2. ``GET_TREE`` once to seed the currently focused ``app_id``.
3. Translate focus changes into events for the pure interval state
   machine (``quadrant_usage``); record ``app_id`` only — titles are
   dropped unless the separate opt-in is enabled.
4. A compositor shutdown or socket loss closes the open interval
   safely.

The collector attaches only when ``$SWAYSOCK`` is set **and** tracking
was enabled by the user — disabling tracking prevents collector
startup, not just recording.

Implemented and unit-tested against a protocol-faithful fake
compositor socket; validation on a live Sway session (reload,
reconnect, logind idle/lock signals) is tracked for the hardware
checklist. The idle and lock adapters currently expose collector events
(``IdleStarted``/``SessionBlanked`` …) that a future logind/D-Bus
adapter will emit; ``/dev/input`` is never read.
