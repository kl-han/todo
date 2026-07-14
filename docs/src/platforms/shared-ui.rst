Shared UI
=========

.. versionadded:: 0.3

One Flutter widget tree serves both platforms; only interaction
conventions differ.

.. versionchanged:: 2.1
   The web platform (:doc:`/platforms/web/index`) becomes a third
   target of the same widget tree. Divergence stays limited to layout
   breakpoints and input conventions (mouse, keyboard, touch); no task
   behavior, parsing rule, or metadata semantics may differ per target.

Structure
---------

* ``AppState`` (``lib/state``): a ``ChangeNotifier`` holding fetched
  snapshots (quadrants, tasks, tags) and issuing every mutation through
  the typed REST client. No business rules, no storage.
* ``HomeShell``: three tabs — **Matrix**, **Tasks**, **Tags** — plus an
  error banner region and refresh affordance.
* ``MatrixScreen``: 2×2 quadrant panels with counts and a quick-add field
  with urgent/important toggles.
* ``TasksScreen``: flat matrix-ordered list with an open/completed/all
  filter.
* ``TagsScreen`` → ``TagTasksScreen``: tag progress list, drilling into a
  tag's sorted, filtered tasks.
* ``TaskTile``: the one focusable task row used everywhere; activation
  (tap or Enter) toggles completion.

.. versionchanged:: 2.1
   ``TaskTile`` splits its interactions: the checkbox toggles
   completion, and activating the rest of the row opens editing by
   default (a setting restores toggle-on-activation). The Tasks tab
   gains grouping, and the Editing / Rules tab joins the shell. See
   :doc:`/product/task-behavior` and :doc:`/product/sorting-filtering`.

Error honesty
-------------

Transport failures surface as a persistent banner ("Backend
unreachable.") with a retry action. A stale-version 412 is not an error
banner: the app refreshes and shows current state instead of overwriting
someone else's change.
