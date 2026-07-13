# Repository rules

- The UI communicates with backends only through the REST client
  (`packages/quadrant_api_client`). No widget or platform code opens SQLite
  or imports store internals.
- Local (embedded) and standalone backends must pass the same conformance
  suite (`packages/quadrant_conformance`) before merge.
- Update `api/openapi.yaml` before implementing an API-breaking change.
- Define product and platform behavior, then tests, then implementation.
- Do not place business rules in widgets or REST handlers; they belong in
  `quadrant_domain` and `quadrant_application`.
- Do not edit generated files directly.
- Every feature change must update the applicable Sphinx pages under
  `docs/src/`; the docs build must stay warning-free
  (`sphinx-build -W --keep-going -b html docs/src docs/build/html`).
- Do not introduce synchronization between local and remote datasets before
  v1.0. Switching backend modes switches the source of truth.
- Do not add performance optimization without measured evidence from real
  usage.
- Errors returned over HTTP use RFC 9457 Problem Details
  (`application/problem+json`); do not invent a separate error envelope.
- One feature per branch (`feature/`, `feat/`, or `claude/` prefix); pull
  requests are squash-merged automatically when marked ready for review
  (see CONTRIBUTING.md).

## Layout

- `api/` — normative OpenAPI contract and problem-type registry.
- `packages/` — pure-Dart packages (domain, application, store, api_server,
  api_client, backend_host, conformance).
- `server/` — standalone backend executable.
- `apps/quadrant_todo/` — Flutter application (not a pub workspace member;
  requires the Flutter SDK).
- `docs/` — Sphinx documentation.
- `devops/` — CI, packaging, and service definitions.

## Commands

- `dart pub get` at the repository root resolves the whole workspace.
- `dart analyze` and `dart test <package>` must pass before merge.
- `make -C docs html` builds the documentation.
