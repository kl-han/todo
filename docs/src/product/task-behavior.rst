Task Behavior
=============

.. versionadded:: 0.2

A task has a title, optional notes, an urgency flag, and an importance
flag. What the user observes:

* Creating a task requires a non-empty title (at most 500 characters,
  surrounding whitespace removed). Notes may hold up to 10,000 characters.
* A task is **open** or **completed**. Completing sets the completion
  time; reopening clears it. Toggling is always allowed in both
  directions.
* Editing title, notes, urgency, or importance never changes the task's
  status.
* Deleting a task is a **soft delete**: it disappears from every list and
  quadrant, but can be restored (undo). Restore returns exactly the task
  that was deleted, including its tags.
* Every visible change to a task counts as a modification: it moves the
  task's position in the least-recently-modified ordering and increments
  its version (:doc:`/api/concurrency`).

Editing activation
------------------

.. versionchanged:: 2.1

The task row separates completing from editing, identically in the
Matrix and Tasks views and on every platform:

* Activating the **checkbox** toggles completion.
* Activating **anywhere else on the row** (click, tap, or keyboard
  activation of the focused task body) opens the task in editing mode.
* A setting changes this default back to toggle-on-activation for users
  who prefer the pre-2.1 behavior.
* Keyboard behavior stays predictable either way: a focused checkbox
  toggles completion; a focused task body opens editing.

Inline metadata entry
---------------------

.. versionadded:: 2.1

While editing a task title (create or edit — the rules are identical in
both flows):

* ``#`` starts **tag entry** with autocomplete over existing tags
  (:doc:`tag-behavior`).
* ``!`` starts **metadata entry** with autocomplete over exactly four
  completions: ``important``, ``not-important``, ``urgent``,
  ``not-urgent``. Confirming one sets the corresponding flag.
* ``!`` followed by a space is a literal exclamation mark followed by
  normal text; it triggers nothing.
* Suggestions are confirmed with ``Enter`` on a keyboard or a click/tap
  on pointer and touch platforms; list navigation is defined in
  :doc:`/reference/keyboard-reference`.

These parsing rules are shared-UI behavior: no platform may interpret
``#`` or ``!`` differently (:doc:`/platforms/shared-ui`).
