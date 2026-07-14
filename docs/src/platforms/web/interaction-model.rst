Interaction Model
=================

The web platform adds no parsing rules and no task semantics of its
own. Task rows, inline metadata entry, and quadrant moves behave as
defined in :doc:`/product/task-behavior`, :doc:`/product/tag-behavior`,
and :doc:`/product/quadrant-behavior`; this page fixes how those
behaviors map onto browser input.

Task rows
---------

The task row keeps two strictly separate interactions, identical in the
Matrix and Tasks tabs:

* clicking or tapping the **checkbox** toggles completion;
* clicking or tapping **anywhere else on the row** opens the task in
  editing mode (the default; a setting restores toggle-on-activation,
  see :doc:`/product/task-behavior`).

Keyboard activation is equally predictable: a focused checkbox toggles
completion, a focused task body opens editing. Desktop web users get
click-to-edit and focus behavior; mobile web users get tap-to-edit; both
follow the same rule.

Inline autocomplete
-------------------

Title editing offers ``#`` tag autocomplete and ``!`` metadata
autocomplete with the shared entry rules (suggestions after ``#``, new
tag ended by a space, no spaces inside tag names, ``!`` before a space
stays literal text). Web-specific requirements:

* **Desktop browsers** — the autocomplete is fully keyboard-operable:
  arrow up/down move through suggestions, ``Ctrl+N`` / ``Ctrl+P`` do the
  same for parity with Linux, ``Enter`` confirms the highlighted
  suggestion (:doc:`/reference/keyboard-reference`).
* **Pointer and touch** — a click or tap on a suggestion confirms it;
  on touch browsers suggestions are large enough to tap reliably.
* Autocomplete behaves identically in the create flow (quick-add) and
  the edit flow.

Drag and drop
-------------

The Matrix supports moving tasks between quadrants by drag and drop.
Dropping a task into a quadrant updates its urgency and importance
flags through the REST client; quadrant membership itself is never
stored (:doc:`/product/quadrant-behavior`).

* **Desktop web** — standard HTML/pointer drag patterns.
* **Touch web** — touch drag, or an equivalent accessible fallback such
  as explicit move controls or a move action in the task editor.
* **Drop targets** are clearly defined, and the pending change is shown
  visually before the drop so an accidental move is hard to make.
* A **keyboard-accessible alternative** (a move-to-quadrant action on
  the focused task) exists regardless of drag support; accessibility
  never depends on drag and drop alone (:doc:`accessibility`).

Drag and drop in grouped Tasks views may be added where the drop target
maps to an unambiguous metadata change (for example dragging between
urgency/importance groups); a drop never performs an operation the task
editor could not.
