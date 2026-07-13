API Contract Tests
==================

.. versionadded:: 0.2

Two layers verify the REST contract:

Handler tests (``quadrant_api_server/test``)
   HTTP semantics against in-memory repository fakes: ETag emission,
   ``If-Match`` parsing and 412s with ``current_version``, 400 problems
   for malformed bodies/headers/query parameters, 404 for unknown vaults,
   409 for duplicate tag names, 204 deletes, restore, tag assignment, and
   the quadrant read model's shape.

Conformance suite (``quadrant_conformance``)
   The same behaviors executed over real HTTP against a real embedded
   isolate and a real standalone server process
   (:doc:`backend-conformance`). This is the merge gate.

The division of labor: handler tests give precise failures fast; the
conformance suite proves both production backends serve the identical
contract. New API behavior must land in both in the same change.
