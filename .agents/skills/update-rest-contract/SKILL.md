# update-rest-contract

Trigger: any change to routes, request/response shapes, status codes, or
headers.

1. Edit `api/openapi.yaml` FIRST — it is normative. Additive-only within
   v1: new routes, new optional fields, new feature names; never change or
   remove existing meaning (docs/src/api/compatibility.rst).
2. Register any new problem `type` in `api/problem-types/README.md` and
   `docs/src/api/errors.rst`.
3. Mirror the change in:
   - `quadrant_api_server` handlers (single implementation for BOTH backends),
   - `quadrant_api_client` typed methods/DTOs,
   - the conformance suite (assert the new behavior over the wire),
   - `apps/quadrant_todo/test/fake_backend.dart`,
   - the relevant `docs/src/api/*.rst` summary page with a
     `.. versionadded::` directive.
4. If a new feature is negotiable, add its name to the capabilities
   `features` list in the router and the conformance assertion.
5. Run the conformance suite against both harnesses; a behavior passing on
   one backend and failing on the other blocks merge.

Never add a route to one backend only — both serve `buildApiHandler`.
