ADR-0003: Embedded Backend as a Dart Isolate
============================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

Local mode needs an HTTP server inside the Flutter application process.
Options: serve from the UI isolate, manage an OS thread, or spawn a Dart
isolate.

Decision
--------

Spawn a dedicated backend isolate that owns the HTTP listener, REST
routing, SQLite connection, application services, and migrations. The UI
isolate never opens SQLite directly.

Startup binds ``127.0.0.1`` port ``0`` (OS-assigned ephemeral port),
generates a random 256-bit per-launch token, reports the port to the UI
isolate, and readiness is confirmed by polling ``/api/v1/health``.

Consequences
------------

* Database work and request handling never block the UI thread.
* Isolate message passing is limited to bootstrap and shutdown; all data
  flows over HTTP like in remote mode.
* On iOS the isolate freezes with the suspended process, so every write
  commits before its HTTP response and resume re-verifies health,
  restarting the isolate if needed.
* The backend must not be reachable off-device: loopback binding plus the
  per-launch token, which is never persisted.
