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
``tag_id=<uuid>``, ``filter=<rule>``, ``sort=matrix_modified_asc``
(:doc:`/product/sorting-filtering`).

.. versionadded:: 1.8
   ``filter`` applies a boolean filter rule over task metadata (terms
   ``tag``, ``important``, ``urgent``; comparison ``tag = <name>``;
   operators ``not``/``and``/``or`` with parentheses). A malformed rule
   is a ``400`` validation problem. The rule composes (AND) with the
   other filters and with the fixed sort order, and is advertised by the
   ``filter-rules`` capability. Server support is negotiated through
   ``GET /api/v1/capabilities`` (:doc:`system-api`).

Semantics worth remembering:

* Task responses embed the derived ``quadrant`` and the active
  ``tag_ids``; single-task responses carry an ``ETag``.
* ``PATCH`` accepts any subset of ``title``, ``notes``, ``is_urgent``,
  ``is_important``, ``status``, the schedule fields, and
  ``estimated_minutes``, and honors ``If-Match`` (:doc:`concurrency`).
* ``DELETE`` returns ``204``; the task then 404s everywhere except
  ``POST .../restore``, which is idempotent.
* Tag assignment/removal return the updated task; assigning an existing
  tag is a no-op that does not bump the version.

.. versionadded:: 1.1

Schedule fields (:doc:`/product/scheduling-behavior`): each side is
``start_kind``/``due_kind`` (``none|date|datetime``) with ``start_date``/
``due_date`` (plain ``YYYY-MM-DD``) for date kinds or ``start_at_utc``/
``due_at_utc`` (RFC 3339 instant with explicit offset) for datetime
kinds, plus one task-level ``timezone_id`` (required iff a datetime side
exists) and optional ``estimated_minutes``:

* A side's kind and value must be consistent, or the request is a 400
  validation problem — a date-only value is never coerced to an instant.
* ``PATCH`` merges by side: providing a kind resets that side to exactly
  the values provided with it; providing a value alone updates it under
  the existing kind. Clearing the last datetime side sheds an inherited
  ``timezone_id``.
* ``estimated_minutes`` accepts an explicit JSON null in ``PATCH`` to
  clear the estimate.
