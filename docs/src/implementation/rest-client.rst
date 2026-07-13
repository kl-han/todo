REST Client
===========

.. versionadded:: 0.2

``quadrant_api_client`` is the only way any UI code reaches a backend.

Shape
-----

* One ``QuadrantApiClient`` per backend, constructed with ``baseUrl`` and
  the full ``Authorization`` header value; vault-scoped methods default to
  the ``default`` vault.
* Typed methods mirror the OpenAPI operations one-to-one (``listTasks``,
  ``createTask``, ``updateTask``, ``deleteTask``, ``restoreTask``,
  ``assignTag``, ``quadrants``, ``listTags``, ``tagTasks``, …).
* Optimistic concurrency is explicit: mutating methods take
  ``ifMatchVersion`` and send ``If-Match: "<n>"``.

Error taxonomy
--------------

* ``ApiUnavailableException`` — transport failure; the UI's explicit
  offline state.
* ``ProblemDetailsException`` — any RFC 9457 problem body, with ``status``
  and ``type`` for precise handling (e.g. 412 → refresh-and-retry).
* ``UnexpectedResponseException`` — non-problem error body; a contract
  violation, surfaced loudly.

``waitUntilHealthy`` polls ``/api/v1/health`` and is used at bootstrap and
resume.
