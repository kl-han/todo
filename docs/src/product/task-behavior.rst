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
