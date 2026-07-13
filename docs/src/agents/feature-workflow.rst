Feature Workflow
================

The specification-first cycle every feature follows:

.. code-block:: text

   intent → product/platform behavior → REST contract
         → failing acceptance and contract tests
         → domain and application logic
         → HTTP, SQLite, and UI adapters
         → iOS / Linux / server verification
         → documentation and ADR update

As a checklist:

1. Define observable product behavior (``docs/src/product``).
2. Define iOS and Linux interaction behavior (``docs/src/platforms``).
3. Define or update the REST contract (``api/openapi.yaml``).
4. Write backend conformance tests (the suite runs against both
   backends).
5. Write domain tests.
6. Write platform acceptance tests where practical.
7. Implement domain/application behavior.
8. Implement REST handlers and persistence.
9. Implement iOS and Linux presentation.
10. Run the API suite against embedded **and** standalone backends.
11. Update the Sphinx pages touched by the change.
12. Record an ADR if an architectural decision changed — required for any
    change crossing two or more architectural boundaries.

One branch, one pull request, one squash commit; the PR is marked ready
only after the quality gates pass (:doc:`/devops/quality-gates`).
