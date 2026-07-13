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
