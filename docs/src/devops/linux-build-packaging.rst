Linux Build and Packaging
=========================

.. versionadded:: 0.3

Prerequisites (Arch): ``flutter`` (stable), ``clang cmake ninja gtk3``.

.. code-block:: bash

   make dist-linux
   make dist-linux FLUTTER="fvm flutter"   # when using FVM

Equivalent explicit commands:

.. code-block:: bash

   cd apps/quadrant_todo
   flutter create --platforms=linux .   # once, generates linux/ runner
   flutter build linux --release
   # Bundle appears under build/linux/x64/release/bundle/

Run locally with ``flutter run -d linux``. The binary is self-contained
apart from GTK; the vault lives in ``$XDG_DATA_HOME/quadrant-todo/``.

Packaging for Arch (PKGBUILD) and a `.desktop` entry are part of the v0.9
release-candidate work (:doc:`release-process`); until then the release
bundle directory is the distributable.
