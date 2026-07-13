Acceptance Tests
================

.. versionadded:: 0.5

Acceptance means: a complete user-visible outcome works end-to-end
through real components — real embedded backend, real vault file, real
widget tree.

Automated (``integration_test/``)
---------------------------------

* Boot → create → toggle → backend restart → durability
  (``linux_local_test.dart``; the same test runs on an iOS simulator).

Manual checklist per release (v0.5 scope)
-----------------------------------------

1. **CRUD**: create, edit (title/notes/flags/tags), complete, reopen.
2. **Undo**: swipe-delete and editor-delete both offer Undo; Undo brings
   back the exact task, tags intact.
3. **Filtering**: status and quadrant filters combine correctly on the
   Tasks tab; tag drill-down lists match tag progress numbers.
4. **Sorting**: the neglected-first matrix order holds after edits.
5. **States**: empty vault shows guidance, not blankness; kill the
   backend → explicit error banner; retry recovers.
6. **Backup**: snapshot the vault, wipe, restore, relaunch — identical
   data (:doc:`/devops/database-backup`).
7. **Accessibility**: task rows announce title/status/quadrant to the
   screen reader; all controls reachable by keyboard (Linux) and by
   VoiceOver (iOS); text scales at large Dynamic Type.
