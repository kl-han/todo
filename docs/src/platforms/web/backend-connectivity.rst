Backend Connectivity
====================

The browser is a REST client and nothing else.

* Web code talks to backends **only** through
  ``packages/quadrant_api_client``. It never opens SQLite, never
  imports ``quadrant_store`` or other backend internals, and holds no
  business rules (:doc:`/architecture/rest-boundary`).
* Backend errors surface through the existing RFC 9457 Problem Details
  model (:doc:`/architecture/error-model`); the web app introduces no
  separate error envelope.
* Stale-version behavior is unchanged: mutations send ``If-Match`` when
  a version is known, and a 412 means refresh to truth — never
  overwrite, never a scary error (:doc:`/api/concurrency`).
* Transport failure is the same explicit banner with retry as on every
  platform; the web app never silently falls back to a different
  dataset.

Base URL configuration
----------------------

The backend base URL is configurable:

* when the standalone server itself serves the web app, the default
  base URL is the serving origin;
* otherwise the user configures the server URL explicitly, with the
  same **Test connection** diagnostics the backend settings sheet
  provides on other platforms (:doc:`/product/backend-modes`).

A browser page served from one origin and talking to a server on
another is a cross-origin client; the standalone server must therefore
answer preflight requests and send the appropriate CORS headers for
that deployment shape. The exact CORS policy is an open server-side
decision tracked in :doc:`/todo`.

Sync and auth boundaries
------------------------

The web app treats local, standalone, and future remote backends
uniformly as HTTP services. Switching backend modes switches the source
of truth according to :doc:`/product/backend-modes`. Preparation for
v3.0 remote sync and remote auth is specified in
:doc:`sync-auth-preparation`; no undocumented sync shortcut is
implemented before that milestone.
