Focus API
=========

.. versionadded:: 1.3

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/focus-sessions``
     - Query sessions (``active=true|false``, ``task_id``)
   * - ``POST``
     - ``/vaults/{id}/focus-sessions``
     - Start a session (409 while one is active)
   * - ``GET``
     - ``/vaults/{id}/focus-sessions/{session_id}``
     - Read one session
   * - ``PATCH``
     - ``/vaults/{id}/focus-sessions/{session_id}``
     - Pause, resume, or finish

Semantics worth remembering:

* ``PATCH`` takes ``action`` (``pause``/``resume``) or ``result``
  (``completed``/``cancelled``/``interrupted``, optionally ``notes``) —
  not both. Invalid transitions are 409 conflicts; writes honor
  ``If-Match``.
* ``active_seconds``/``paused_seconds`` accumulate at transitions only;
  responses are deterministic. Clients render the live timer from
  ``phase`` + ``last_transition_at`` + a local clock.
* At most one unfinished session per vault; sessions reference at most
  one of ``task_id``/``occurrence_id`` and survive their deletion
  (references null out, history stays).
