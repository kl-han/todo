Terminology
===========

Backend
   Any process serving the Quadrant Todo REST API.

Embedded backend
   The backend hosted inside the Flutter application process as a dedicated
   Dart isolate, bound to ``127.0.0.1`` on an ephemeral port. Powers local
   mode.

Standalone backend / server
   The independent ``quadrant_server`` process an operator runs. Powers
   remote mode.

Backend mode
   Which backend the application is connected to: ``local`` or ``remote``.
   Changing mode changes the active dataset; nothing is merged or copied.

Vault
   One SQLite database of tasks and tags. The embedded backend uses a fixed
   internal vault (``default``); a standalone server can host several.

Quadrant
   Derived classification of a task: Q1 urgent and important, Q2 important
   only, Q3 urgent only, Q4 neither. Never stored, always computed.

Local session token
   Random 256-bit per-launch credential for the embedded backend, sent as
   ``Authorization: Local <token>`` and never persisted.

Problem Details
   The RFC 9457 ``application/problem+json`` error format used for every
   non-2xx response.

Conformance suite
   The backend contract test suite that must pass unchanged against both
   backend kinds.
