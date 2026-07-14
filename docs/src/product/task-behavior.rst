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
* The task title editor supports inline metadata entry. Typing ``#``
  opens tag autocomplete; selecting an existing tag assigns it to the
  task. If the user continues typing a new tag, the next space ends tag
  entry. Tag names cannot contain spaces.
* Typing ``!`` opens importance and urgency autocomplete with
  ``important``, ``not-important``, ``urgent``, and ``not-urgent``. When
  ``!`` is immediately followed by a space, it is normal title text.
* A task row separates completion from editing. Activating the checkbox
  toggles completion; activating the non-checkbox area enters editing by
  default. That editing default may be changed in settings.
* Deleting a task is a **soft delete**: it disappears from every list and
  quadrant, but can be restored (undo). Restore returns exactly the task
  that was deleted, including its tags.
* Every visible change to a task counts as a modification: it moves the
  task's position in the least-recently-modified ordering and increments
  its version (:doc:`/api/concurrency`).
