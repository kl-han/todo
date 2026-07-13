# implement-vertical-slice

Trigger: adding or changing user-visible behavior (a new task/tag
capability, a new view, a changed rule).

Follow the specification-first cycle (docs/src/agents/feature-workflow.rst):

1. Write/update the product behavior page under `docs/src/product/` and the
   affected platform pages under `docs/src/platforms/`.
2. Update `api/openapi.yaml` if the wire contract changes (see the
   `update-rest-contract` skill).
3. Add the behavior to `packages/quadrant_conformance/lib/src/suite.dart`
   (failing first).
4. Add domain tests, then implement in `quadrant_domain` /
   `quadrant_application`.
5. Implement persistence in `quadrant_store` (+ migration if the schema
   moves — see `add-database-migration`).
6. Implement the route in `quadrant_api_server` and the method in
   `quadrant_api_client`.
7. Implement UI in `apps/quadrant_todo` with widget tests against
   `test/fake_backend.dart` (extend the fake in the same PR).
8. Run the gate: `dart analyze --fatal-infos`, package tests, the
   conformance suite (both harnesses), `sphinx-build -W`.
9. One branch, one PR, quality gates green before marking ready.

Layer map: references/layer-map.md. Never put rules in widgets or
handlers; never let presentation import the store.
