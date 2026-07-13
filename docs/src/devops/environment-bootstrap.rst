Environment Bootstrap
=====================

Requirements
------------

* Dart SDK ≥ 3.9 (stable). Flutter SDK (stable) additionally for the app
  in ``apps/quadrant_todo``.
* ``libsqlite3`` available to the dynamic linker (the ``sqlite3`` Dart
  package loads the system library).
* Python ≥ 3.11 with ``sphinx`` and ``furo`` for documentation.

Setup
-----

.. code-block:: bash

   # Pure-Dart workspace (packages/, server/)
   dart pub get            # at the repository root; resolves the workspace
   dart analyze
   dart test packages/quadrant_conformance   # or per-package `dart test`

   # Flutter application (requires Flutter SDK)
   cd apps/quadrant_todo
   flutter create --platforms=ios,linux .    # once, generates runners
   flutter pub get
   flutter test

   # Documentation
   pip install sphinx furo
   make -C docs html

The Flutter app is intentionally not a pub-workspace member so the
pure-Dart toolchain (and CI) never needs the Flutter SDK; see
``devops/bootstrap/`` for scripted setup.
