REST API Additions
==================

The following resources join the API contract. As with every API
change, ``api/openapi.yaml`` is updated first and remains normative;
this page only summarizes the additions.

.. code-block:: text

   /tasks/{id}/recurrence
   /occurrences
   /reminders
   /focus-sessions
   /plans/{date}
   /reports/weekly

   /agent/status
   /agent/tracking/start
   /agent/tracking/pause
   /agent/usage/intervals
   /agent/usage/daily
   /agent/applications
   /agent/categories

Local agent endpoints bind only to loopback and use a per-install
credential.

Remote usage upload
-------------------

If — and only if — remote upload is explicitly enabled:

.. code-block:: text

   POST /api/v1/vaults/{vault}/usage/daily:batch

Each aggregate batch carries an idempotency key. If remote upload is
unavailable, the agent keeps a bounded local outbox. This is
technically a limited synchronization mechanism and is documented as
such; it moves only daily aggregates, never raw intervals (see
:doc:`/decisions/adr-0005-no-sync-before-v1` for the v1.0 boundary it
extends).
