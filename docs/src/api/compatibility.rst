Compatibility
=============

.. versionadded:: 0.7

Negotiation
-----------

Remote-mode clients verify the server before trusting it:

1. ``GET /api/v1/health`` — reachability (unauthenticated).
2. ``GET /api/v1/capabilities`` — credential validity, ``api_version``,
   ``schema_version``, and the feature list.
3. ``GET /api/v1/vaults`` — the configured vault exists.

A server that answers with an ``api_version`` other than ``v1`` is
**incompatible**: the app refuses to proceed with a clear error instead of
degrading, because retrying cannot fix a protocol mismatch.

Versioning policy
-----------------

.. versionchanged:: 1.0
   The v1 contract is **frozen**: everything in ``api/openapi.yaml`` as
   of 1.0.0 is stable.

* ``v1`` is additive-only from v1.0: new routes, new optional fields,
  and new ``features`` entries may appear; existing fields never change
  meaning or disappear.
* Clients must ignore unknown response fields and unknown feature names.
* A breaking change would be ``/api/v2/`` served alongside ``v1`` —
  out of scope before v1.0.
* ``schema_version`` is informational for diagnostics; clients make no
  decisions on it.

Feature names shipped in v0.7: ``tasks``, ``tags``, ``quadrants``,
``vaults``, ``etag-concurrency``, ``soft-delete-restore``.
