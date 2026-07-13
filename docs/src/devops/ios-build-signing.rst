iOS Build and Signing
=====================

.. versionadded:: 0.4

Prerequisites: macOS with Xcode, a Flutter SDK, and an Apple ID (a free
personal team suffices for personal-device installs).

.. code-block:: bash

   cd apps/quadrant_todo
   flutter create --platforms=ios .     # once, generates ios/ runner
   open ios/Runner.xcworkspace          # set Team + bundle identifier
   flutter run -d <device>              # debug install on the iPhone
   flutter build ipa                    # release archive (paid account)

Notes:

* With a free team, provisioning profiles expire after 7 days; re-run
  ``flutter run`` to refresh — acceptable for personal use until v0.9
  decides on distribution.
* No special entitlements are needed: the app uses loopback networking
  and the standard sandbox only. Remote mode (v0.7) adds outbound HTTPS,
  which requires nothing beyond ATS defaults.
* The generated ``ios/`` runner is a host artifact; all behavior lives in
  ``lib/`` (:doc:`/implementation/package-map`).
