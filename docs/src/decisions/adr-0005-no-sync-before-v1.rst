ADR-0005: No Synchronization Before v1.0
========================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

With a local dataset and a remote dataset, the tempting feature is to
merge or mirror them. Synchronization is an entire subsystem — conflict
resolution, identity mapping, partial failure, corruption spread — and it
would dominate the project before the product itself exists.

Decision
--------

There is no synchronization subsystem before v1.0. Switching backend mode
switches the source of truth; it does not merge or copy data. Remote mode
is online-only, and unreachability is presented as an explicit offline
error rather than a fallback to local data.

Consequences
------------

* Each dataset stays internally consistent by construction; there are no
  merge conflicts because there are no merges.
* The mode selector must make the dataset switch unmistakable (v0.7
  includes protection against accidental switching).
* Import/export and any future sync design happen after v1.0 as separate
  capabilities with their own ADRs.
