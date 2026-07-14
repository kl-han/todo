Configuration Reference
=======================

Locations
---------

.. list-table::
   :header-rows: 1
   :widths: 30 40 30

   * - What
     - Linux
     - iOS
   * - Local vault
     - ``$XDG_DATA_HOME/quadrant-todo/default.sqlite3``
     - ``~/Library/Application Support/quadrant-todo/`` (sandbox)
   * - Server vaults
     - ``$XDG_DATA_HOME/quadrant-todo/vaults/*.sqlite3``
     - —
   * - Server token
     - ``~/.config/quadrant-todo/token`` (0600)
     - —
   * - Remote credentials
     - Secret Service, else 0600 files
     - Keychain
   * - Daemon pid file
     - ``$XDG_RUNTIME_DIR/quadrant-server.pid``
     - —

Environment variables
---------------------

* ``XDG_DATA_HOME`` / ``XDG_RUNTIME_DIR`` — standard XDG resolution with
  ``~/.local/share`` and ``/tmp`` fallbacks.
* The server reads no other environment; every knob is a flag
  (:doc:`command-reference`).

Linux debug mode
----------------

Linux clients may expose a configurable debug mode. When enabled, the UI
shows a debug toggle next to the sync control and records key events plus
the application events they trigger. The debug log is exportable so the
interaction path can be inspected without reading local storage directly.

Tokens
------

The embedded backend's ``Local`` token is generated per launch and never
configurable or persisted. The server's ``Bearer`` token is operator
data; generate with ``openssl rand -base64 32`` and store 0600.
