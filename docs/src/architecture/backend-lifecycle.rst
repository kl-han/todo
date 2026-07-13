Backend Lifecycle
=================

Embedded backend startup
------------------------

Implemented in ``packages/quadrant_backend_host``:

1. Generate a random per-launch session token (256 bits, in memory only).
2. Spawn the backend isolate (``Isolate.spawn``), not a managed thread.
3. The isolate opens and migrates the SQLite database (from v0.2).
4. The isolate binds an HTTP server to ``127.0.0.1`` port ``0``; the OS
   assigns an unused ephemeral port.
5. The isolate reports the bound port back to the UI isolate.
6. The UI isolate constructs the typed REST client and polls
   ``/api/v1/health`` until ready, then renders the application.

Shutdown and suspension
-----------------------

The embedded server is not a daemon; it exists only inside the application
process. When iOS suspends the application, the backend isolate is
suspended with it — acceptable, because the UI is suspended at the same
time. The correctness rules that follow:

* Every write commits before its successful HTTP response is sent.
* The backend never depends on receiving a shutdown event; Flutter
  lifecycle notifications can be skipped entirely.
* On resume, the application verifies backend health and restarts the
  isolate if necessary (``BackendConnection.ensureHealthy``).
* No scheduled background backend work exists before v1.0.

Standalone server lifecycle
---------------------------

The standalone server runs in the foreground by default and shuts down
cleanly on ``SIGINT``/``SIGTERM``. Daemon mode, PID files, and vault
management arrive in v0.6 (:doc:`/platforms/server/index`).
