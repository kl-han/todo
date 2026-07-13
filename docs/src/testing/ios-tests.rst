iOS Tests
=========

.. versionadded:: 0.4

Simulator/workstation layer
---------------------------

* Widget tests cover the iPhone-sized layout (390×844 logical) selecting
  the single-column matrix, the editor sheet round-trip, and delete —
  ``flutter test`` on any machine with a Flutter SDK.
* ``flutter test integration_test -d <simulator>`` runs the same
  end-to-end flow as Linux (boot on a temp vault, create, toggle,
  restart, verify durability).

Physical-device checklist (iPhone 13 Pro)
-----------------------------------------

Required for the v0.4 exit and repeated at v0.9; cannot be automated from
this repository:

1. Cold start to interactive matrix; create/toggle/edit/delete tasks.
2. Background the app (home), reopen — state intact, no spinner stuck.
3. Force-quit mid-use, relaunch — every acknowledged write present.
4. Leave the app suspended for hours (jetsam likely), relaunch — backend
   restarts transparently via the resume health check.
5. Rotate, Dynamic Type at larger sizes, VoiceOver labels on task rows.
6. Airplane mode: local mode fully functional (no network dependency).
