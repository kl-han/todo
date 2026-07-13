iOS Local Backend Lifecycle
===========================

.. versionadded:: 0.4

The embedded backend is not an iOS daemon; it exists only inside the app
process. iOS may suspend or kill the process at any time, and lifecycle
notifications are not guaranteed to be delivered.

Correctness therefore never depends on shutdown events:

* Every write commits before its 2xx response
  (:doc:`/architecture/persistence-concept`), so a jetsam kill loses
  nothing acknowledged.
* On ``AppLifecycleState.resumed`` the app calls
  ``AppState.ensureBackendHealthy()``: poll ``/api/v1/health``; on
  failure, restart the backend isolate via the bootstrap's ``restart``
  closure and refresh. This is a best-effort acceleration — the same
  recovery runs whenever any request fails transport-level.
* No scheduled background work exists before v1.0; the backend does
  nothing while the UI cannot be seen.

Suspension freezing the backend is acceptable by design: the UI that
would talk to it is frozen at the same time.
