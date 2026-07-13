Conventions
===========

* The normative contract is ``api/openapi.yaml`` in the repository root.
  Documentation summarizes it but never contradicts it; API-breaking
  changes update the contract first.
* All routes are versioned under ``/api/v1/``.
* All vault data routes use ``/api/v1/vaults/{vault_id}/...``; the embedded
  backend serves a fixed internal vault named ``default``.
* Request and response bodies are JSON (``application/json``); errors are
  Problem Details (``application/problem+json``, :doc:`errors`).
* Field names are ``snake_case`` on the wire.
* Authentication: ``Authorization: Local <token>`` against the embedded
  backend, ``Authorization: Bearer <token>`` against a standalone server.
  Only ``GET /api/v1/health`` is unauthenticated.
* Mutable resources carry a numeric ``version`` and an ``ETag``; updates
  send ``If-Match`` (:doc:`concurrency`).
* Timestamps are UTC ISO-8601 strings; identifiers are UUIDs.
