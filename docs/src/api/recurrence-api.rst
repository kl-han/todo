Recurrence API
==============

.. versionadded:: 1.2

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``PUT``
     - ``/vaults/{id}/tasks/{task_id}/recurrence``
     - Attach or replace the task's rule
   * - ``GET``
     - ``/vaults/{id}/tasks/{task_id}/recurrence``
     - Read the rule
   * - ``DELETE``
     - ``/vaults/{id}/tasks/{task_id}/recurrence``
     - Detach the rule (idempotent)
   * - ``GET``
     - ``/vaults/{id}/occurrences``
     - Materialize and list occurrences in ``[from, to]``
   * - ``GET``
     - ``/vaults/{id}/occurrences/{occurrence_id}``
     - Read one occurrence
   * - ``PATCH``
     - ``/vaults/{id}/occurrences/{occurrence_id}``
     - Complete, skip, reopen, or reschedule

Rules are RFC 5545 RRULE text, supported subset:
``FREQ=DAILY|WEEKLY|MONTHLY``, ``INTERVAL``, ``BYDAY`` (with an ordinal
for monthly: ``2TU``, ``-1FR``), ``BYMONTHDAY``, ``COUNT``, ``UNTIL``
(date). Examples: ``FREQ=WEEKLY;BYDAY=MO,WE,FR``,
``FREQ=MONTHLY;BYMONTHDAY=31``, ``FREQ=MONTHLY;BYDAY=-1FR;COUNT=6``.

Semantics worth remembering:

* ``GET /occurrences`` requires ``from``/``to`` (inclusive, ≤ 366 days)
  and materializes idempotently before answering — identical rules
  yield identical occurrence sets on both backends. ``status`` filters
  ``open|completed|skipped|all``; ``task_id`` narrows to one task.
* An occurrence's ``original_date`` is its permanent identity;
  rescheduling moves ``occurrence_date``/``occurrence_at_utc`` only,
  records a ``rescheduled`` exception, and prevents regeneration.
* ``PATCH`` takes either a ``status`` or a reschedule value matching
  the occurrence's kind — not both. Occurrence writes honor
  ``If-Match``.
* ``COUNT`` is consumed from ``dtstart``, so early occurrences use the
  budget even when queried later.
