# Changelog

All notable changes; one entry per squash-merged milestone.

## v1.1.0 — Temporal foundation

- Tasks carry an optional **start** and **due** schedule: each side is
  `none`, a plain date (`YYYY-MM-DD`, never stored as midnight UTC), or a
  UTC instant with a task-level IANA `timezone_id`; plus optional
  `estimated_minutes`. Scheduling never changes the quadrant.
- New **agenda read model** (`GET /vaults/{id}/agenda?from&to`): scheduled
  tasks grouped by task-local calendar date, DST-correct via the tz
  database, identical on both backends.
- `PATCH` merges schedules by side; providing a kind resets that side;
  clearing the last datetime side sheds an inherited timezone;
  `estimated_minutes: null` clears the estimate.
- Schema v2 migration (additive columns) with its frozen released-schema
  fixture; API document 1.1.0 with additive `Task`/`TaskCreate`/`TaskPatch`
  fields and the `AgendaReport` schema; capabilities now advertise
  `temporal` and `agenda`.
- Conformance suite extended with the temporal contract (round-trips,
  side-merging, validation problems, agenda grouping across the UTC
  boundary).

## v1.0.0 — Stable release

- **v1 REST contract frozen**: additive-only from here; upgrade and
  rollback policy documented (`docs/src/api/compatibility.rst`,
  `docs/src/devops/release-process.rst`).
- Released-schema migration fixtures: a frozen snapshot of every shipped
  schema (currently v1) must migrate to current with data intact; a guard
  test fails when a release forgets to add its fixture.
- All packages, the app, and the OpenAPI document versioned 1.0.0.
- README rewritten with iOS/Linux/server installation instructions (the
  architecture text it previously held lives in `docs/`).
- Upgrade policy: newer-schema vaults refuse to open under older builds;
  restore the pre-upgrade verified snapshot to roll back.

## v0.9.0 — Release candidate

- Completed the documentation set (agents, devops, references); no stub
  pages remain.
- Initial repository skills under `.agents/skills/` and nested `AGENTS.md`
  rules for the app, API server, server, and docs.
- Packaging artifacts: Arch PKGBUILD template and desktop entry; release
  process with rollback and the RC validation checklist.

## v0.8.0 — Hardening

- Corrupt local vaults are moved aside (timestamped) and recreated at
  boot; the server stays strict-open. Newer-schema refusal is preserved.
- Self-verifying backups (`integrity_check` + downgrade guard); the
  server backup command fails loudly on unsound snapshots.
- Conformance: stale `If-Match` on DELETE, additive tolerance of unknown
  request fields, clean 401 problems for wrong tokens (44 assertions per
  backend). Backend restart-after-death proven against an on-disk vault.
- The app names authentication failures instead of showing generic errors.

## v0.7.0 — Remote backend mode

- `GET /api/v1/capabilities` with client-side version negotiation;
  incompatible servers produce a clear fatal error, unreachable ones an
  explicit offline state.
- Backend settings sheet with connection diagnostics and a dataset-switch
  confirmation; settings persisted to `backend.json`, credentials only in
  the platform credential store.

## v0.6.0 — Standalone server

- Multi-vault serving (`--data-dir`, strict name validation, explicit
  `vault-create`), `GET /api/v1/vaults`, mandatory bearer auth, daemon
  mode with pid/log files, clean SIGINT/SIGTERM, `backup` subcommand,
  hardened systemd user service.

## v0.5.0 — Local feature-complete beta

- Undo for every deletion path (swipe + editor), quadrant filter chips,
  `VACUUM INTO` vault snapshots, backup/restore documentation,
  acceptance checklist.

## v0.4.0 — iOS local alpha

- Phone-width single-column matrix, bottom-sheet task editor with tag
  chips, iOS sandbox vault path, keychain-ready `CredentialStore` with a
  0600-file Linux fallback.

## v0.3.0 — Linux local alpha

- Three-tab shell (Matrix/Tasks/Tags), quadrant grid, tag progress and
  drill-down, `Alt+1/2/3`, `h/j/k/l`, Enter toggle, text-focus shortcut
  suppression, offline banner, resume recovery, widget + integration
  tests.

## v0.2.0 — Domain and persistence

- Task/tag domain with derived quadrants and version-bumping transitions;
  SQLite store (WAL + FULL sync, append-only migrations, matrix sort in
  SQL); full CRUD REST API with ETag/If-Match and RFC 9457 problems;
  typed client; conformance suite expansion.

## v0.1.0 — Architectural walking skeleton

- Dart workspace, shared `/api/v1/health` handler, embedded backend
  isolate (loopback + per-launch token), standalone server, typed client,
  first conformance suite, OpenAPI skeleton, full Sphinx tree, CI.
