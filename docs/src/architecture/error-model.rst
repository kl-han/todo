Error Model
===========

Every non-2xx response across the API is an RFC 9457 Problem Details body
with ``Content-Type: application/problem+json``. There is no other error
envelope, and inventing one is prohibited.

.. code-block:: json

   {
     "type": "problems/unauthenticated",
     "title": "Unauthenticated",
     "status": 401,
     "detail": "A valid Authorization header is required."
   }

Rules
-----

* ``type`` values are registered in ``api/problem-types/`` as they are
  introduced; ``about:blank`` is reserved for generic status-only errors.
* Servers produce problems through a single builder
  (``problemResponse`` in ``quadrant_api_server``); handlers never
  hand-assemble error JSON.
* The typed client surfaces problems as ``ProblemDetailsException`` and
  transport failures as ``ApiUnavailableException``; a non-problem error
  body is a contract violation (``UnexpectedResponseException``).
* Concurrency conflicts (v0.2+) use ``412 Precondition Failed`` with a
  problem body; see :doc:`/api/concurrency`.
