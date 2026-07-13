# API server rules (packages/quadrant_api_server)

- One handler for every backend: routes are added to `buildApiHandler`
  and nowhere else. A route existing on one backend only is a defect.
- Handlers translate HTTP ↔ application services; no quadrant rules, no
  validation logic, no SQL here.
- All errors flow through `problemResponse` / `problemMiddleware` as
  RFC 9457 problems; never hand-assemble error JSON, never invent an
  envelope. New `type` values are registered in `api/problem-types/`.
- Body/query parsing uses the typed helpers (`readJsonObject`,
  `optional`, `required_`) so bad input is a 400, never a 500; unknown
  request fields are ignored (additive compatibility).
- Mutable resources carry `ETag`; writes honor `If-Match` via
  `expectedVersionFrom`.
- `api/openapi.yaml` changes precede handler changes; every behavior
  added here lands in the conformance suite in the same PR.
