Release Process
===============

.. versionadded:: 0.9

Cut
---

1. All quality gates green on ``main`` (:doc:`quality-gates`).
2. Bump ``version``/``release`` in ``docs/src/conf.py``, ``api/openapi.yaml``
   ``info.version``, and the package pubspecs when the API surface moved.
3. Update ``CHANGELOG.md`` from the squash-commit log.
4. Tag ``vX.Y.0``; build artifacts:

   .. code-block:: bash

      dart compile exe server/bin/quadrant_server.dart -o dist/quadrant_server
      (cd apps/quadrant_todo && flutter build linux --release)
      (cd apps/quadrant_todo && flutter build ipa)          # macOS host

Release-candidate validation (v0.9 exit)
----------------------------------------

Sustained real use — days, not minutes — on every deployment shape, with
defects filed and fixed before v1.0:

* iPhone 13 Pro (physical device), local mode: the iOS checklist in
  :doc:`/testing/ios-tests`.
* Arch Linux + Sway, local mode: the Sway checklist in
  :doc:`/testing/linux-tests`.
* Foreground server + remote mode from both platforms, including a
  deliberate server outage (explicit offline state, no fallback).
* systemd-managed server (:doc:`server-service`), including restart and
  ``backup``/restore drills with verification.
* Accessibility pass: VoiceOver on iOS, keyboard-only on Linux, large
  type on both.

Fix observed correctness and usability problems; do **not** optimize on
synthetic benchmarks (:doc:`/intro/goals-and-non-goals`).

Rollback
--------

Artifacts are versioned and vaults are per-file: reinstall the previous
build and restore the pre-upgrade verified snapshot
(:doc:`database-backup`). A newer-schema vault refuses to open under an
older build by design — restore the snapshot rather than forcing it.
