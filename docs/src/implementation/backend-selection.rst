Backend Selection
=================

.. versionadded:: 0.7

Persistence
-----------

``BackendSettings`` (mode, remote URL, vault) serialize to
``~/.config/quadrant-todo/backend.json`` via ``SettingsStore``
(``quadrant_backend_host``). The bearer token is **not** in that file; it
lives in the platform ``CredentialStore`` keyed by
``quadrant-todo/<host>/<vault>``. A corrupt settings file falls back to
local mode — the app must always boot.

Boot path
---------

``bootstrapFromSettings`` (``apps/quadrant_todo/lib/bootstrap/``):

* local → ``bootstrapLocalBackend`` (embedded isolate).
* remote → read the credential; if missing, boot local and flag it;
  otherwise ``bootstrapRemoteBackend``, which health-checks and
  negotiates capabilities. Unreachable ⇒ boot anyway into the explicit
  offline state (retry can fix it); wrong API version ⇒
  ``IncompatibleBackendException`` and a fatal explanation (retry cannot).

Switching at runtime
--------------------

The settings sheet re-runs ``bootstrapFromSettings`` and hands the new
connection to ``AppState.switchConnection``, which shuts the old backend
down and refreshes. Switching is guarded by an explicit confirmation
spelling out that the visible dataset changes and nothing is merged
(:doc:`/decisions/adr-0005-no-sync-before-v1`).

Diagnostics
-----------

"Test connection" runs ``diagnoseRemoteBackend``: reachability →
credential → API version → vault existence, reporting the first failure
in plain language (:doc:`/api/compatibility`).
