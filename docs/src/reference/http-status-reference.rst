HTTP Status Reference
=====================

Every non-2xx body is an RFC 9457 problem (:doc:`/api/errors`).

.. list-table::
   :header-rows: 1
   :widths: 10 30 60

   * - Status
     - Problem ``type``
     - Meaning / typical trigger
   * - 200
     - —
     - Read or update succeeded; mutable resources carry ``ETag``
   * - 201
     - —
     - Task or tag created
   * - 204
     - —
     - Soft delete succeeded
   * - 400
     - ``problems/validation``
     - Malformed JSON/If-Match/query value, or a domain rule failed
   * - 401
     - ``problems/unauthenticated``
     - Missing or wrong ``Authorization`` (only ``/health`` is open)
   * - 404
     - ``problems/not-found``
     - Unknown route, vault, task, or tag (including soft-deleted)
   * - 409
     - ``problems/conflict``
     - Duplicate active tag name
   * - 412
     - ``problems/version-conflict``
     - Stale ``If-Match``; body carries ``current_version``

Semantics guaranteed by the conformance suite: unknown request fields
are ignored (additive compatibility); a 2xx write is durably committed;
the two backends never differ beyond the health report's ``backend``
field.
