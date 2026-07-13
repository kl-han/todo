Reminder API
============

.. versionadded:: 1.2

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/reminders``
     - Query by state and trigger horizon
   * - ``POST``
     - ``/vaults/{id}/reminders``
     - Create for a task or an occurrence
   * - ``GET``
     - ``/vaults/{id}/reminders/{reminder_id}``
     - Read one reminder
   * - ``PATCH``
     - ``/vaults/{id}/reminders/{reminder_id}``
     - Advance state / record platform id
   * - ``DELETE``
     - ``/vaults/{id}/reminders/{reminder_id}``
     - Delete

Semantics worth remembering:

* A reminder references exactly one of ``task_id``/``occurrence_id``.
  ``trigger_type`` is ``absolute`` (with ``trigger_at_utc``) or
  ``relative_start``/``relative_due`` (with ``offset_minutes``);
  relative triggers require the referenced side to be a date-time.
* ``effective_trigger_at_utc`` is **recomputed from the current
  schedule on every read**, never cached: moving a task moves its
  relative reminders, and clearing the referenced side makes the
  trigger null.
* The recovery loop (launch, reboot, agent restart, timezone change) is
  ``GET /reminders?state=...&until=<horizon>`` → ``PATCH
  state=pending`` (which discards the stale ``platform_schedule_id``)
  → reschedule with the OS → ``PATCH state=scheduled`` with the new
  platform id. Reminder writes honor ``If-Match``, which is the
  idempotency guard against double-scheduling.
* Delivery adapters per platform (Quadrant Agent on desktop, local
  notification APIs on mobile) are specified in
  :doc:`/post-v1/reminders` and arrive with the v1.3 agent.
