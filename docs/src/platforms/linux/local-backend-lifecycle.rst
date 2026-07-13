Linux Local Backend Lifecycle
=============================

.. versionadded:: 0.3

Linux is the simple lifecycle platform: no suspension, no jetsam. The
embedded backend isolate lives exactly as long as the process.

* Vault location: ``$XDG_DATA_HOME/quadrant-todo/default.sqlite3``
  (falling back to ``~/.local/share``).
* Window close ends the process; the durability settings guarantee no
  acknowledged write is lost (``WAL`` + ``synchronous=FULL``).
* The resume health-check hook exists on Linux too (it is shared code) but
  in practice only fires after rare compositor-level freezes; it restarts
  the backend isolate if health polling fails.

The integration test
(``apps/quadrant_todo/integration_test/linux_local_test.dart``) proves the
cycle: boot on a temp vault, create and toggle through the UI, restart the
backend, and observe the committed state.
