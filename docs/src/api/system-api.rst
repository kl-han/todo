System API
==========

.. list-table::
   :header-rows: 1
   :widths: 10 30 60

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/api/v1/health``
     - Process readiness
   * - ``GET``
     - ``/api/v1/capabilities``
     - API version, schema version, supported features (v0.7)
   * - ``GET``
     - ``/api/v1/vaults``
     - List accessible vaults; primarily remote mode

Health
------

``GET /api/v1/health`` is the only unauthenticated route. Clients poll it
during startup before constructing an authenticated client, and on resume
to detect a dead embedded backend.

.. versionadded:: 0.1

.. code-block:: json

   {
     "status": "ok",
     "api_version": "v1",
     "schema_version": 0,
     "backend": "embedded"
   }

``backend`` is the only field that may differ between backend kinds
(``embedded`` or ``standalone``); everything else in the API is
behaviorally identical by contract.

Vaults
------

.. versionadded:: 0.6

``GET /api/v1/vaults`` returns the accessible vault names. The embedded
backend always answers exactly ``[{"id": "default"}]``; a standalone
server lists every vault in its data directory
(:doc:`/platforms/server/vault-files`).
