Errors
======

All errors are RFC 9457 Problem Details; see
:doc:`/architecture/error-model` for the architectural rules.

Registered problem types
------------------------

.. list-table::
   :header-rows: 1
   :widths: 40 10 50

   * - ``type``
     - Status
     - Meaning
   * - ``about:blank``
     - any
     - Generic problem; ``title`` matches the status phrase
   * - ``problems/unauthenticated``
     - 401
     - Missing or invalid ``Authorization`` header
   * - ``problems/not-found``
     - 404
     - Resource or route does not exist

.. versionadded:: 0.1
   ``problems/unauthenticated`` and ``problems/not-found``.

The registry of record is ``api/problem-types/`` in the repository; new
types are added there in the same change that introduces them.
