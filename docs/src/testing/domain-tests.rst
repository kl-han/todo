Domain Tests
============

.. versionadded:: 0.2

``packages/quadrant_domain/test`` covers the pure business rules with no
I/O:

* Quadrant derivation for all four flag combinations.
* Status transitions: complete sets ``completed_at``, reopen clears it,
  and every transition increments ``version`` and refreshes
  ``updated_at``.
* Soft delete / restore round-trips.
* Validation rules: trimming, emptiness, length limits, color format.
* UUID generation shape and uniqueness.

Because entities are immutable and transitions are pure functions of
``(entity, now)``, these tests need no fixtures or fakes — they are the
executable form of :doc:`/architecture/domain-model`.
