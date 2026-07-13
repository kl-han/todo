Database Backup
===============

.. versionadded:: 0.5

A vault is one SQLite file; backup and restore are file-level.

Snapshot (safe while running)
-----------------------------

The store exposes ``QuadrantDatabase.backupTo(path)``, which runs SQLite's
``VACUUM INTO`` — a consistent, compacted snapshot that does not block
the live database. The standalone server wraps this as a command (v0.6).

Manual local backup
-------------------

.. code-block:: bash

   # Linux (app closed, or use sqlite3's online backup):
   cp "$XDG_DATA_HOME/quadrant-todo/default.sqlite3" backup-$(date +%F).sqlite3
   # Or, safe while running:
   sqlite3 "$XDG_DATA_HOME/quadrant-todo/default.sqlite3" \
     "VACUUM INTO 'backup-$(date +%F).sqlite3'"

iOS: the vault lives in Application Support inside the sandbox and is
included in device backups automatically; explicit export ships with a
later milestone.

Restore
-------

1. Stop the app or server (the vault must not be open).
2. Replace ``default.sqlite3`` with the snapshot (remove any ``-wal`` /
   ``-shm`` files alongside it).
3. Restart. Migrations bring an older snapshot forward automatically; a
   snapshot from a *newer* build is refused
   (:doc:`/implementation/migrations`).
