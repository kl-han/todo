Plan API
========

.. versionadded:: 1.6

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/plans/{date}``
     - Read the plan (created empty on first read)
   * - ``PATCH``
     - ``/vaults/{id}/plans/{date}``
     - Record the daily review (notes, status)
   * - ``POST``
     - ``/vaults/{id}/plans/{date}/items``
     - Place a task or occurrence into the day
   * - ``PATCH``
     - ``/vaults/{id}/plans/{date}/items/{item_id}``
     - Reorder, schedule, re-estimate, record the outcome
   * - ``DELETE``
     - ``/vaults/{id}/plans/{date}/items/{item_id}``
     - Remove an item
   * - ``GET``
     - ``/vaults/{id}/plans/{date}/accuracy``
     - Planned versus actual focus time

Semantics worth remembering:

* One plan per local date (``YYYY-MM-DD``); the plan's
  ``planned_minutes`` is the derived sum of its items.
* Items reference exactly one of ``task_id``/``occurrence_id``; adding
  the same reference twice is a 409. New items append at the end.
* ``planned_minutes``, ``scheduled_start`` (``HH:MM``), and ``outcome``
  accept explicit JSON null in PATCH to clear. Writes honor
  ``If-Match``.
* Accuracy counts focus sessions started on that local date.
