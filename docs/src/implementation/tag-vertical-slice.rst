Tag Vertical Slice
==================

.. versionadded:: 0.5

The tag feature follows the same layering as tasks
(:doc:`task-vertical-slice`); the notable tag-specific pieces:

* **Progress is a SQL aggregate**
  (``SqliteTagRepository.progressOf``), not stored state — completed and
  total across the tag's non-deleted tasks, computed per read.
* **Name uniqueness is a partial unique index** on live tags
  (:doc:`sqlite-schema`); the service turns the constraint into a
  ``StateConflictException`` → ``409`` rather than letting SQLite errors
  escape.
* **Membership changes touch the task, not the tag**: assigning or
  removing a tag bumps the *task's* version and ``updated_at`` (it
  changed observably); renaming a tag touches only the tag.
* **Deletion decouples**: a soft-deleted tag disappears from
  ``tag_ids`` and tag lists; ``task_tags`` rows remain so a restore
  concept could return them, but tasks never cascade.

UI: ``tags_screen.dart`` (progress bars, creation),
``tag_tasks_screen.dart`` (drill-down list), and the editor's tag chips
(assignment).
