Backend Conformance
===================

The most important test artifact in the project is the reusable backend
contract suite in ``packages/quadrant_conformance``:

.. code-block:: text

   BackendContractSuite
   ├── EmbeddedBackendHarness     (real backend isolate, in-process)
   └── StandaloneBackendHarness   (real quadrant_server OS process)

``runBackendContractSuite`` encodes every normative REST behavior exactly
once. Each harness starts a real backend of its kind — the embedded
harness spawns the actual isolate used by the app; the standalone harness
launches ``server/bin/quadrant_server.dart`` as a separate process and
parses its "listening on" line — and the identical assertions run against
both.

Rules
-----

* Every REST behavior added to the API must be asserted in the suite in
  the same change.
* The only assertion allowed to differ per harness is the ``backend``
  field of the health report.
* A behavior passing on one backend and failing on the other blocks merge;
  that asymmetry is precisely the defect class this suite exists to catch.

Running
-------

.. code-block:: bash

   cd packages/quadrant_conformance
   dart test
