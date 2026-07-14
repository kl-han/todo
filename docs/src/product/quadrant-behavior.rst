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
* Quadrant backgrounds use low-opacity status color so task text remains
  readable: urgent-and-important is red, urgent-only is orange,
  important-only is purple, and neither urgent nor important is white or
  neutral. The status color opacity is approximately 10%.
* Activating empty space inside a quadrant starts creating a new task in
  that quadrant. The new task inherits urgency and importance from the
  quadrant where creation began.
* Dragging a task between quadrants updates its urgency and importance
  flags to match the destination quadrant. Drag and drop is an input
  method for changing task metadata; it does not create stored quadrant
  membership.
* Within a quadrant, tasks appear in the deterministic matrix order
  (:doc:`sorting-filtering`).
