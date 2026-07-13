Test Commands
=============

.. code-block:: bash

   # Everything the CI quality gate runs:
   dart pub get
   dart analyze                                   # zero issues required

   (cd packages/quadrant_api_server   && dart test)
   (cd packages/quadrant_api_client   && dart test)
   (cd packages/quadrant_backend_host && dart test)
   (cd packages/quadrant_conformance  && dart test)   # both harnesses
   (cd server                         && dart test)

   # Documentation must build warning-free:
   sphinx-build -W --keep-going -b html docs/src docs/build/html

Root distribution wrappers:

.. code-block:: bash

   make dist-server    # compile standalone server to build/server/quadrant_server
   make dist-linux     # generate Linux runner if needed and build release bundle
   make dist-ios       # generate iOS runner if needed and build IPA

Pass ``FLUTTER="fvm flutter"`` to the Flutter targets when using FVM.

The conformance package is the merge gate: it starts a real embedded
backend isolate and a real standalone server process and runs the same
contract suite against both (:doc:`/testing/backend-conformance`).

Flutter widget and integration tests run where a Flutter SDK and the
target platforms exist:

.. code-block:: bash

   cd apps/quadrant_todo
   flutter test
   flutter test integration_test    # on a device/desktop session
