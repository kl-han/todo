Agenda API
==========

.. versionadded:: 1.1

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/agenda``
     - Scheduled tasks grouped by task-local date

Query parameters: ``from=YYYY-MM-DD`` and ``to=YYYY-MM-DD`` (both
required, inclusive, at most 366 days apart) and
``status=open|completed|all``.

Semantics worth remembering:

* Grouping is by **task-local** date: the stored date for date-only
  values, or the instant rendered in the task's ``timezone_id`` for
  date-time values — never the server's timezone.
* Each scheduled side contributes one entry with ``kind`` (``start`` or
  ``due``), ``time_local`` (``HH:MM`` or null for all-day), and the
  embedded task.
* Days are ascending; days without entries are omitted. Within a day,
  all-day entries come first, then timed entries by time, then task id.
* Inverted or oversized ranges are 400 validation problems.
