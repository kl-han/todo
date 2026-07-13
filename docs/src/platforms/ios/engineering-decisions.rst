iOS Engineering Decisions
=========================

.. versionadded:: 0.4

* **Single-column matrix under 600 logical pixels**: a 2×2 grid on an
  iPhone 13 Pro produces unusably small panels; a Q1-first column keeps
  the "do first" quadrant on top where scrolling starts.
* **Bottom sheet editor, not a pushed page**: editing is a short
  interruption of a list workflow; a sheet preserves list context and
  dismisses with a swipe.
* **Application Support over Documents** for the vault: not user-visible,
  still backed up (:doc:`storage-security`).
* **Resume recovery over shutdown handling**: iOS does not promise
  lifecycle events, so recovery logic runs on resume and on transport
  failure instead (:doc:`local-backend-lifecycle`).
* **Same widget tree as Linux**: platform divergence is confined to
  layout breakpoints and input conventions; forked screens would drift.
