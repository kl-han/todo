Security Boundaries
===================

Embedded (loopback) backend
---------------------------

Binding to loopback alone is not treated as sufficient isolation:

* The server binds only to ``127.0.0.1``; binding to ``0.0.0.0`` is
  prohibited.
* The port is ephemeral (OS-assigned per launch).
* Every request except ``GET /api/v1/health`` must carry
  ``Authorization: Local <token>`` with the random 256-bit per-launch
  session token.
* The local session token is never persisted; it exists only in process
  memory and dies with the launch.
* Diagnostic routes are disabled in release builds.

Standalone server
-----------------

* Data routes require ``Authorization: Bearer <token>`` with a persistent
  token (mandatory from v0.6).
* Remote transport is HTTPS; the client refuses to silently downgrade.

Credential storage (remote mode)
--------------------------------

* iOS: Keychain.
* Linux: Secret Service when available; otherwise a configuration file
  with ``0600`` permissions.

Failure honesty
---------------

If the remote backend is unreachable, the UI presents an explicit offline
error. Silent fallback to the local dataset would silently change the
source of truth and is prohibited.
