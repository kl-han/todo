Agent API
=========

.. versionadded:: 1.4

Routes under ``/api/v1/agent/*`` are served **only by the quadrant
agent** on loopback — they are not part of the vault contract in
``api/openapi.yaml`` and the conformance suite never asserts them
against the embedded or standalone backends. All except ``status``
require the per-install bearer token.

.. list-table::
   :header-rows: 1
   :widths: 10 45 45

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/agent/status``
     - Liveness + scheduler tick + tracking state (open, like health)
   * - ``GET``
     - ``/agent/tracking``
     - Current privacy/tracking state
   * - ``POST``
     - ``/agent/tracking/start`` / ``/agent/tracking/stop``
     - Enable/disable tracking (durable consent)
   * - ``POST``
     - ``/agent/tracking/pause`` ``{minutes}``
     - Auto-expiring pause (runtime-only)
   * - ``POST``
     - ``/agent/tracking/private`` ``{enabled}``
     - Private mode; entering it closes the open interval
   * - ``PUT``
     - ``/agent/tracking/exclusions`` ``{application_ids}``
     - Replace the exclusion list
   * - ``GET``
     - ``/agent/usage/intervals?from&to``
     - Raw intervals (RFC 3339 range); local only, never uploaded
   * - ``GET``
     - ``/agent/usage/daily?from&to``
     - Daily aggregates (date range)
   * - ``DELETE``
     - ``/agent/usage``
     - Delete all usage history (tasks untouched)
