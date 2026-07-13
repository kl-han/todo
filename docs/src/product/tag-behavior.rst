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
