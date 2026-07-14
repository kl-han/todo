Tag Behavior
============

.. versionadded:: 0.2

Tags group tasks across quadrants (projects, contexts, people).

* A tag has a name (unique among live tags, at most 100 characters) and a
  ``#rrggbb`` color.
* Any number of tags can be assigned to a task; assignment and removal are
  idempotent and count as task modifications.
* Every tag shows **progress**: completed / total across its non-deleted
  tasks.
* Renaming or recoloring a tag never touches its tasks.
* Deleting a tag is a soft delete: tasks keep existing and simply lose the
  tag from their tag sets. A new tag may then reuse the name.

Inline ``#`` tag entry
----------------------

.. versionadded:: 2.1

Tags can be entered directly while editing a task title
(:doc:`task-behavior`):

* Typing ``#`` shows suggestions from the existing tags; the suggestion
  list narrows as the user keeps typing.
* A suggestion is confirmed with ``Enter``, or with a click/tap; the
  confirmed tag is assigned to the task.
* Typing a name that matches no existing tag and ending it with a space
  **creates** the tag and assigns it.
* Tag names contain no spaces: the space is what terminates inline tag
  entry, so a name cannot include one. This restriction applies to tag
  creation everywhere, not just inline entry, so every tag remains
  addressable via ``#``. (Whether pre-2.1 tag names with spaces need a
  migration is tracked in :doc:`/todo`.)
