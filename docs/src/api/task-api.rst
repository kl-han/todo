Task API
========

.. versionadded:: 0.2

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/tasks``
     - Query tasks
   * - ``POST``
     - ``/vaults/{id}/tasks``
     - Create task
   * - ``GET``
     - ``/vaults/{id}/tasks/{task_id}``
     - Read one task
   * - ``PATCH``
     - ``/vaults/{id}/tasks/{task_id}``
     - Edit title, notes, status, or classification
   * - ``DELETE``
     - ``/vaults/{id}/tasks/{task_id}``
     - Soft-delete task
   * - ``POST``
     - ``/vaults/{id}/tasks/{task_id}/restore``
     - Restore recently deleted task
   * - ``PUT``
     - ``/vaults/{id}/tasks/{task_id}/tags/{tag_id}``
     - Assign tag
   * - ``DELETE``
     - ``/vaults/{id}/tasks/{task_id}/tags/{tag_id}``
     - Remove tag

Query parameters: ``status=open|completed|all``, ``quadrant=1|2|3|4``,
``tag_id=<uuid>``, ``sort=matrix_modified_asc``
(:doc:`/product/sorting-filtering`).

Semantics worth remembering:

* Task responses embed the derived ``quadrant`` and the active
  ``tag_ids``; single-task responses carry an ``ETag``.
* ``PATCH`` accepts any subset of ``title``, ``notes``, ``is_urgent``,
  ``is_important``, ``status`` and honors ``If-Match``
  (:doc:`concurrency`).
* ``DELETE`` returns ``204``; the task then 404s everywhere except
  ``POST .../restore``, which is idempotent.
* Tag assignment/removal return the updated task; assigning an existing
  tag is a no-op that does not bump the version.
