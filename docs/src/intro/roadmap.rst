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

After v1.0, real measurements (startup time, request latency, database
size, memory, large-list behavior) determine the first performance
milestone. No optimization happens on synthetic evidence.
