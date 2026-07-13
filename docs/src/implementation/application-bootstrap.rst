Application Bootstrap
=====================

.. versionadded:: 0.3

``apps/quadrant_todo/lib/bootstrap/`` owns process startup; presentation
code never constructs backends.

Local mode (default)
--------------------

``bootstrapLocalBackend``:

1. Resolve the vault path (``$XDG_DATA_HOME/quadrant-todo/`` on Linux;
   the app sandbox on iOS from v0.4).
2. ``EmbeddedBackend.start(databasePath: …)`` — spawns the backend
   isolate, which opens/migrates SQLite and binds ``127.0.0.1:0``.
3. Build ``QuadrantApiClient`` with ``Authorization: Local <token>``.
4. ``waitUntilHealthy()`` before the first frame renders data.
5. Return a ``BackendConnection`` carrying ``shutdown`` and ``restart``
   closures; ``AppState.ensureBackendHealthy()`` uses ``restart`` on app
   resume.

Remote mode (v0.7)
------------------

``bootstrapRemoteBackend`` skips the isolate and configures the same
client against a ``RemoteBackendProfile`` plus a stored credential. No
fallback path exists between the two bootstraps by design.
