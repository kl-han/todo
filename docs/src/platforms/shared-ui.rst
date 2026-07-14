Shared UI
=========

.. versionadded:: 0.3

One Flutter widget tree serves supported client platforms; only
interaction conventions differ. The UI issues every backend operation
through the typed REST client.

Structure
---------

* ``AppState`` (``lib/state``): a ``ChangeNotifier`` holding fetched
  snapshots (quadrants, tasks, tags) and issuing every mutation through
  the typed REST client. No business rules, no storage.
* ``HomeShell``: three tabs — **Matrix**, **Tasks**, and **Editing /
  Rules** — plus an error banner region and refresh affordance.
* ``MatrixScreen``: 2×2 quadrant panels with counts and a quick-add field
  with urgent/important toggles. Dragging a task between panels updates
  the task's urgency and importance flags. Activating empty space in a
  panel starts a new task with that panel's urgency and importance.
* ``TasksScreen``: matrix-ordered task lists with open/completed/all
  filtering plus grouping or aggregation by tag, importance/urgency, or
  both.
* ``EditingRulesScreen``: filter rule management for boolean task views.
* ``TaskTile``: the one focusable task row used everywhere. Checkbox
  activation toggles completion; non-checkbox activation enters editing
  by default.
* Task title editing supports ``#`` tag autocomplete and ``!``
  importance/urgency autocomplete. Desktop-style platforms use keyboard
  selection; touch platforms allow tapping suggestions.

Error honesty
-------------

Transport failures surface as a persistent banner ("Backend
unreachable.") with a retry action. A stale-version 412 is not an error
banner: the app refreshes and shows current state instead of overwriting
someone else's change.
