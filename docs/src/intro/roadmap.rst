Roadmap
=======

.. list-table::
   :header-rows: 1
   :widths: 8 46 46

   * - Version
     - Implementation scope
     - Required documentation and tests
   * - v0.1
     - Repository, Sphinx, OpenAPI skeleton, health API, embedded server
       spike
     - Architecture foundations, REST ADR, health contract tests
   * - v0.2
     - Task and tag domain, SQLite, CRUD REST API
     - Domain model, task/tag API, repository and migration tests
   * - v0.3
     - Linux local alpha
     - Sway design, keyboard behavior, Linux acceptance tests
   * - v0.4
     - iOS local alpha
     - iOS navigation/lifecycle, physical-device tests
   * - v0.5
     - Local feature-complete beta
     - Quadrants, progress, filtering, sorting, deletion/restore
   * - v0.6
     - Standalone server
     - Foreground/daemon modes, vault management, server tests
   * - v0.7
     - Remote backend mode
     - Backend selector, authentication, HTTPS/error behavior
   * - v0.8
     - Compatibility hardening
     - ETag concurrency, API compatibility, migration/backup recovery
   * - v0.9
     - Release candidate
     - Packaging, signing, complete docs, real personal-use validation
   * - v1.0
     - Stable release
     - Frozen v1 API, release checklist, documented upgrade policy
   * - v1.1
     - Temporal foundation: start/due dates, date-only versus
       date-time, timezone behavior, agenda view
     - Temporal model, API/database migration, DST and timezone tests
   * - v1.2
     - Recurrence and reminders
     - Recurrence rules, occurrence materialization, notification
       adapters, reboot/resume rescheduling tests
   * - v1.3
     - Pomodoro and desktop agent (``quadrant-agent``)
     - Focus sessions, agent lifecycle, startup integration,
       pause/resume/recovery tests
   * - v1.4
     - Windows and Sway usage collection
     - Collectors, ``usage.sqlite3``, privacy controls, daily
       aggregation, lock/suspend tests
   * - v1.5
     - Android usage integration
     - Usage Access onboarding, scheduled import,
       permission-revocation behavior; iOS entitlement spike
   * - v1.6
     - Daily planning and calendar
     - Daily plan, agenda/week/day views, planned-versus-actual
   * - v1.7
     - Weekly review
     - Cross-device aggregates, weekly report, category mappings,
       export
   * - v2.0
     - Integrated personal planning release
     - Full acceptance list in :doc:`/post-v1/milestones`
   * - v2.1
     - Web platform: responsive browser frontend over the REST client
       (Matrix / Tasks / Editing–Rules shell, quadrant colors and drag
       and drop, inline ``#``/``!`` metadata entry, grouped task views,
       boolean filter rules)
     - Web platform pages, product-behavior updates, responsive and
       accessibility tests, autocomplete and rule-validation tests,
       REST-boundary tests
   * - v3.0
     - Remote sync and remote authentication, with web as the primary
       remote-client surface
     - Sync semantics, auth/session/logout/expiry behavior
       (:doc:`/platforms/web/sync-auth-preparation`), browser auth-state
       storage decision, expired-session tests

Post-v1 milestones are specified in detail in :doc:`/post-v1/index`.

After v1.0, real measurements (startup time, request latency, database
size, memory, large-list behavior) determine the first performance
milestone. No optimization happens on synthetic evidence.
