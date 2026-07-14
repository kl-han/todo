Quadrant Behavior
=================

.. versionadded:: 0.2

The matrix view shows four quadrants, derived from each open task's flags:

.. code-block:: text

   Q1 = urgent && important        (do first)
   Q2 = !urgent && important       (schedule)
   Q3 = urgent && !important       (delegate/minimize)
   Q4 = !urgent && !important      (reconsider)

Rules the user can rely on:

* Quadrant membership is never stored and never edited directly; changing
  the urgency/importance flags is the only way a task moves between
  quadrants, and it moves instantly.
* The quadrant view always presents all four groups, each with its task
  count, even when empty.
* Within a quadrant, tasks appear in the deterministic matrix order
  (:doc:`sorting-filtering`).

Quadrant colors
---------------

.. versionadded:: 2.1

Each quadrant panel carries a background tint at about 10% opacity so
foreground text keeps normal contrast:

* Q1 (urgent + important): red
* Q3 (urgent only): orange
* Q2 (important only): purple
* Q4 (neither): white / neutral

Color is presentation only and never the sole indicator: every quadrant
keeps its heading and task count, and each task's urgency and importance
remain available as text and accessibility semantics.

Drag and drop
-------------

.. versionadded:: 2.1

A task can be dragged from one quadrant panel and dropped on another.
The drop is nothing more than an urgency/importance edit: it updates the
two flags through the REST boundary, exactly as if they had been toggled
in the editor. Quadrant membership itself is still never stored. Drop
targets are indicated before the drop, and platforms without reliable
drag input provide an equivalent move action — pointer drag is a
convenience, not the mechanism (:doc:`/platforms/web/interaction-model`).
