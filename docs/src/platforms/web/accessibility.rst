Accessibility
=============

Desktop web supports a full keyboard session; mobile web supports
touch-first operation; assistive technology gets the same information
and the same actions as everyone else.

Keyboard
--------

* Every tab (Matrix, Tasks, Editing / Rules) is keyboard reachable —
  by standard focus traversal and by the ``Alt+number`` chords shared
  with Linux (:doc:`/reference/keyboard-reference`).
* Inline autocomplete is keyboard reachable end to end: open, navigate
  (arrows or ``Ctrl+N`` / ``Ctrl+P``), confirm (``Enter``), dismiss —
  without touching the pointer.
* Moving a task between quadrants has a non-pointer path (a
  move-to-quadrant action on the focused task); drag and drop is a
  convenience, never the only way (:doc:`interaction-model`).

Semantics
---------

* Task rows expose the checkbox and the edit action as **separate**
  accessible actions, so "toggle completion" and "open editor" are
  individually reachable by assistive technology.
* Screen readers can identify a task's status (open/completed),
  urgency, importance, tags, and available actions from the row itself.

Color and contrast
------------------

* Color is never the only indicator of quadrant meaning: each quadrant
  carries its heading and task count, and a task's urgency and
  importance are exposed as text/semantics, not just background tint
  (:doc:`/product/quadrant-behavior`).
* The quadrant background colors are applied at about 10% opacity
  precisely so foreground text keeps its normal contrast; text on
  tinted quadrants must remain readable in both light and dark themes.
