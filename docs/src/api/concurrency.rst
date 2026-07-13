Concurrency
===========

.. versionadded:: 0.2

Every mutable resource carries a numeric ``version``, exposed both in the
body and as a strong ``ETag`` (``"7"``). Every domain mutation increments
it.

Protocol
--------

.. code-block:: http

   PATCH /api/v1/vaults/default/tasks/{id} HTTP/1.1
   If-Match: "7"
   Content-Type: application/json

   {"status": "completed"}

* ``If-Match`` matches the current version → the write applies and the
  response carries the new ``ETag``.
* ``If-Match`` is stale → ``412 Precondition Failed`` with a
  ``problems/version-conflict`` problem whose ``current_version``
  extension carries the live version, letting clients re-fetch and retry
  deliberately.
* ``If-Match`` absent → the write is unconditional. Interactive edits
  should always send it; v0.8 revisits whether to require it.
* A malformed ``If-Match`` is a ``400`` validation problem.

``PATCH`` and ``DELETE`` on tasks and tags honor the header. Restore and
tag assignment/removal are idempotent by design and do not take
preconditions.
