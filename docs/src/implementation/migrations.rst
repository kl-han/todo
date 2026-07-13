Migrations
==========

.. versionadded:: 0.2

Migrations are an append-only list of SQL scripts in
``quadrant_store``; ``PRAGMA user_version`` records how many have been
applied. Opening a vault applies any missing migrations inside a
transaction, one at a time, then reports the resulting version through
``/api/v1/health`` as ``schema_version``.

Rules
-----

* **Append-only**: a migration that has shipped in any released version is
  never edited. Fixes are new migrations.
* Each migration is transactional; a failure rolls back and leaves the
  database at its previous version.
* A database whose version is *newer* than the running build refuses to
  open rather than risk corruption (downgrade protection).
* v1.0 requires migration tests from **every** released schema version to
  current; the store test suite grows one fixture per release.
