Behavior Specifications
=======================

Every feature is specified before it is implemented, layer by layer. The
canonical example, completion toggling:

.. list-table::
   :header-rows: 1
   :widths: 15 85

   * - Layer
     - Required behavior
   * - Product
     - Open becomes completed; completed becomes open
   * - Domain
     - Set or clear ``completed_at``; increment version
   * - REST
     - ``PATCH /tasks/{id}`` with new status and ``If-Match``
   * - iOS
     - Tap the task row
   * - Linux
     - ``Enter`` on the focused task
   * - Persistence
     - Commit before returning ``200``
   * - Conflict
     - Stale version returns ``412``
   * - Tests
     - Same result against local and standalone backends

The row set is the checklist for every feature: product behavior first
(``docs/src/product/``), platform interaction next
(``docs/src/platforms/``), contract change third (``api/openapi.yaml``),
then failing tests, then implementation
(:doc:`/agents/feature-workflow`).

Specifications live in the product pages; this page defines the method.
A feature without all applicable rows filled in is not ready to
implement.
