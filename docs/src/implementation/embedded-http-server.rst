Embedded HTTP Server
====================

.. versionadded:: 0.1

``packages/quadrant_backend_host/lib/src/embedded_backend.dart``.

The backend isolate's ``_backendMain``:

1. Opens (or creates) the vault via ``QuadrantDatabase`` — migrations run
   here, inside the isolate that owns the connection.
2. Builds ``AppServices`` over the SQLite repositories.
3. Builds the shared handler via ``buildApiHandler`` with
   ``BackendKind.embedded``, the per-launch token, and a single-vault
   resolver (``default``).
4. Serves on ``InternetAddress.loopbackIPv4`` port ``0`` — loopback only;
   binding ``0.0.0.0`` is prohibited
   (:doc:`/architecture/security-boundaries`).
5. Reports the bound port to the UI isolate and waits for a stop command,
   on which it closes the HTTP server and the database.

The UI isolate holds only the port, the token, and control send-ports;
all data crosses HTTP exactly as in remote mode. ``EmbeddedBackend.stop``
escalates to ``Isolate.kill`` if the graceful path exceeds its timeout —
and correctness never depends on the graceful path running at all.
