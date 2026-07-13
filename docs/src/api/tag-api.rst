Tag API
=======

.. versionadded:: 0.2

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/tags``
     - Tags with completed/total progress
   * - ``POST``
     - ``/vaults/{id}/tags``
     - Create tag
   * - ``GET``
     - ``/vaults/{id}/tags/{tag_id}``
     - Read tag
   * - ``PATCH``
     - ``/vaults/{id}/tags/{tag_id}``
     - Rename or recolor tag
   * - ``DELETE``
     - ``/vaults/{id}/tags/{tag_id}``
     - Soft-delete tag
   * - ``GET``
     - ``/vaults/{id}/tags/{tag_id}/tasks``
     - Sorted, filtered task list

Semantics:

* Tag responses embed ``progress`` (completed/total across the tag's
  non-deleted tasks) so list views need one request.
* Creating or renaming to a name already used by a live tag is a ``409``
  conflict problem; deleted tags free their names.
* Deleting a tag never deletes tasks; the tag vanishes from their
  ``tag_ids``.
