Database Tests
==============

.. versionadded:: 0.2

``packages/quadrant_store/test`` runs against real in-memory SQLite:

* Migrations bring a fresh database to the current ``user_version``, are
  idempotent on reopen, and refuse databases from newer builds.
* Task rows round-trip every field, including microsecond timestamps.
* The ``matrix_modified_asc`` SQL sort is asserted literally — including
  the deliberately surprising rule that urgency outranks importance.
* Status, quadrant, and tag filters; soft-deleted rows excluded everywhere
  while their rows persist.
* The partial unique index on live tag names (duplicates rejected, names
  reusable after deletion).
* Tag progress counts completed/total across non-deleted tasks only.

Every repository behavior asserted here is exercised again over HTTP by
the conformance suite (:doc:`backend-conformance`), so a store regression
fails twice — once with a precise message here, once as contract
breakage.
