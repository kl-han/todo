Task Vertical Slice
===================

.. versionadded:: 0.5

Where each piece of task behavior lives, top to bottom — the template for
reading (and extending) any feature:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Concern
     - Location
   * - Product behavior
     - :doc:`/product/task-behavior`
   * - Wire contract
     - ``api/openapi.yaml`` (`tasks` operations)
   * - Entity + transitions
     - ``quadrant_domain/lib/src/entities/task.dart``
   * - Validation rules
     - ``quadrant_domain/lib/src/rules/validation.dart``
   * - Commands/queries
     - ``quadrant_application/lib/src/services/task_service.dart``
   * - Repository interface
     - ``quadrant_application/lib/src/repositories.dart``
   * - SQL implementation
     - ``quadrant_store/lib/src/repositories/sqlite_task_repository.dart``
   * - HTTP routes
     - ``quadrant_api_server/lib/src/handlers/vault_routes.dart``
   * - Typed client
     - ``quadrant_api_client`` (`createTask`, `updateTask`, …)
   * - UI state
     - ``apps/quadrant_todo/lib/state/app_state.dart``
   * - Widgets
     - ``task_tile.dart``, ``task_editor.dart``, ``matrix_screen.dart``
   * - Tests
     - domain → store → handler → conformance → widget → integration

A change that skips a layer (say, a rule implemented in the handler, or a
widget calling SQLite) is a review rejection by definition
(:doc:`/architecture/conceptual-layers`).
