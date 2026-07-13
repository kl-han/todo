ADR-0004: SQLite Vault Files
============================

:Status: Accepted
:Date: 2026-07-13

Context
-------

Both backends need durable, transactional, zero-administration storage
suitable for a personal dataset, and the server needs a unit of isolation
and backup.

Decision
--------

One SQLite database file per vault. The embedded backend owns a single
fixed vault (``default``); the standalone server hosts multiple vault
files addressed as ``/api/v1/vaults/{vault_id}/...``. Access goes through
repository interfaces defined by the application layer; only
``quadrant_store`` touches SQLite.

Consequences
------------

* Backup and restore are file-level operations, verifiable in tests.
* Vault names are validated strictly (they map to file paths), preventing
  traversal.
* Migrations run at open time in the process that owns the file; every
  released schema version must remain migratable to current (v1.0 gate).
* Concurrent multi-process access to one vault file is out of scope; a
  vault has exactly one serving process.
