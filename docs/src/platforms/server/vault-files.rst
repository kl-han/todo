Vault Files
===========

.. versionadded:: 0.6

A standalone server hosts one SQLite file per vault under its data
directory:

.. code-block:: text

   ~/.local/share/quadrant-todo/vaults/
   ├── default.sqlite3
   ├── personal.sqlite3
   └── work.sqlite3

Rules:

* Vault names are ``[a-z0-9][a-z0-9_-]{0,63}`` — validated before any
  path is formed, which structurally excludes traversal.
* ``default`` is created on first access. Every other vault must be
  created explicitly (``quadrant_server vault-create <name>``) so a typo
  in a URL 404s instead of minting an empty dataset.
* ``GET /api/v1/vaults`` lists the vaults; data routes address one as
  ``/api/v1/vaults/{vault_id}/...``.
* Vaults are fully isolated datasets: separate files, separate
  migrations, separate backups
  (``quadrant_server backup <vault> <dest>``).
* One serving process per vault directory; concurrent servers on the same
  directory are unsupported (:doc:`/decisions/adr-0004-sqlite-vaults`).
