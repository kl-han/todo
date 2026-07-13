Persistence Concept
===================

.. versionadded:: 0.2

One vault = one SQLite database file
(:doc:`/decisions/adr-0004-sqlite-vaults`). The backend process that owns
a vault is the only process that opens it.

Durability contract
-------------------

The REST guarantee — *a write that received a 2xx response has been
committed* — is enforced at open time: ``journal_mode = WAL`` with
``synchronous = FULL``. The embedded backend may be frozen or killed by
iOS at any moment afterwards without losing acknowledged writes.

Soft deletion
-------------

Deleted tasks and tags keep their rows (``deleted_at`` set) and disappear
from every query via ``WHERE deleted_at IS NULL``. Restore clears the
marker. Time-based purging of old deleted rows is a post-v1.0 concern.

Timestamps
----------

Stored as fixed-width UTC ISO-8601 with microseconds so lexicographic
comparison inside SQLite equals chronological comparison — the
``updated_at ASC`` term of the matrix sort depends on it.

Repositories
------------

``quadrant_store`` implements the repository interfaces with plain SQL —
no ORM. The matrix sort and the tag-progress aggregate live in SQL where
they are cheap and consistent for every caller.
