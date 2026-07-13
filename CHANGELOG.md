# Changelog

All notable changes; one entry per squash-merged milestone.

## v1.7.0 — Weekly review

- **Weekly report** (`GET /reports/weekly?week_start=`, Monday-anchored):
  computed facts only — completed by quadrant plus occurrences,
  carryover from daily plans, due-date performance (on-time/late/
  overdue-open), focus time, planned-versus-actual, Q2 focus investment,
  open Q3 follow-ups, and stale Q4 cleanup candidates. Interpretations
  stay in the presentation layer by design.
- **Finalize** stores a versioned snapshot with user notes (schema v6,
  `weekly_report_snapshots`, insert-or-replace per week); everything
  else stays computed. `format=csv` exports flat section/metric/value
  rows.
- Usage/distraction sections join client-side from the agent's
  `usage.sqlite3`; the task vault never sees behavioral data.
- OpenAPI 1.7.0; capabilities advertise `weekly-review`; conformance
  suite extended with the report contract on both backends.

## v1.6.0 — Daily planning

- **Daily plans**: one per local date, materialized empty on first read
  and filled only by the user — nothing is auto-populated with due tasks.
  Items reference a task or one occurrence (once per day), order by
  position, and carry optional time blocks (`HH:MM` + planned minutes).
- **Outcomes and review**: items record `done|partial|skipped|moved`;
  the plan records review notes and flips to `reviewed`.
- **Planned versus actual**: `GET /plans/{date}/accuracy` compares the
  plan's summed minutes against focus sessions started that local date.
- Schema v5 with its frozen fixture; OpenAPI 1.6.0 (`plans` resources);
  capabilities advertise `daily-plans`; conformance suite extended with
  the daily-plan contract on both backends.

## v1.5.0 — Android usage import core

- Pure `AndroidUsageImporter` in `quadrant_usage`: converts
  `UsageStatsManager` event batches (resume/pause, screen on/off,
  shutdown) into `confidence: derived` intervals, excluding screen-off
  periods, repairing lost pauses, ignoring unknown kinds, sorting
  out-of-order delivery, and applying the privacy policy at import time.
- **Idempotent by watermark**: overlapping re-imports (delayed
  WorkManager runs, re-import on app open) skip already-imported events;
  a span still open at batch end is deferred and re-imported completely
  later — never lost, never duplicated. Revoked Usage Access yields
  empty batches and preserves the watermark.
- Docs: new `platforms/android/usage-import` page; onboarding UI, the
  Kotlin adapter, WorkManager scheduling, and vendor precision checks
  are tracked for device-side validation.

## v1.4.0 — Usage tracking core

- New pure **`quadrant_usage`** package: the event-driven interval state
  machine (focus change / idle / lock / collector stop — no polling),
  monotonic-clock durations (wall-clock jumps can't distort them,
  sub-second flicker dropped), privacy policy gating, and daily
  aggregation.
- **Privacy by default**: tracking off until enabled, app identity only,
  window titles behind a separate opt-in, exclusion list enforced at
  record time, private mode closes the open interval immediately, pause
  auto-expires and never survives a restart while consent does.
- Separate **`usage.sqlite3`** (ADR-0007) with its own migrations:
  raw intervals (pruned after a configurable 7-day retention) and
  long-term `usage_daily` aggregates; delete-day/delete-all never touch
  tasks.
- **Sway IPC collector**: speaks the real i3-ipc protocol over
  `$SWAYSOCK` (SUBSCRIBE window/shutdown + GET_TREE seeding), records
  `app_id` only, attaches only when tracking is enabled; unit-tested
  against a protocol-faithful fake compositor socket.
- Agent API additions (loopback, agent-only): `/agent/tracking[/*]`,
  `/agent/usage/intervals`, `/agent/usage/daily`, `DELETE /agent/usage`.
- Windows collector remains contract + docs pending real hardware, per
  the acceptance checklist.

## v1.3.0 — Focus sessions and the quadrant-agent

- **Focus (Pomodoro) sessions** owned by the backend: `running → paused →
  finished` with results (`completed|cancelled|interrupted`), one active
  session per vault, durations accumulated at transitions with negative
  clock deltas clamped — closing a GUI never cancels a session.
- **`quadrant-agent`** (new package + executable): per-user, loopback-only
  local backend host with a persistent 0600 credential, single-instance
  file lock, corrupt-vault recovery, and a 30-second scheduler that
  delivers due reminders via `notify-send` (idempotent, retrying) and
  announces focus completion once.
- `devops/agent/`: hardened systemd **user** unit (documented via
  literalinclude, replacing the design sketch) and a Windows per-user
  logon Task Scheduler script (explicitly not a Session-0 service).
- Schema v4 (`focus_sessions`) with its frozen fixture; OpenAPI 1.3.0;
  capabilities advertise `focus-sessions`; conformance suite extended
  with the focus contract; agent test proves the "GUI closes during
  Pomodoro" scenario end-to-end over real HTTP.

## v1.2.0 — Recurrence and reminders

- **Recurring tasks** via RFC 5545-subset RRULEs (daily, weekdays, weekly
  by weekday, monthly by date or ordinal weekday, INTERVAL, COUNT, UNTIL)
  in the new pure `quadrant_temporal` package. Occurrences materialize
  idempotently in a rolling window; both backends produce identical sets.
- Each occurrence is its own record (`open|completed|skipped`) —
  completing one never resets the task or touches siblings. Skips and
  reschedules record **exceptions** keyed by the original date; a
  rescheduled occurrence keeps its identity and is never regenerated.
- Date-time tasks recur at the same wall-clock time in the task's
  timezone (UTC instants shift across DST transitions).
- **Reminders**: absolute or relative (`relative_start`/`relative_due`)
  records with delivery state and `platform_schedule_id`; the effective
  trigger is recomputed from the current schedule on every read, giving
  reboot/timezone-change recovery without cached staleness.
- Schema v3 (recurrence_rules, task_occurrences, recurrence_exceptions,
  reminders, tasks.recurrence_rule_id) with its frozen fixture; OpenAPI
  1.2.0; capabilities advertise `recurrence` and `reminders`; conformance
  suite extended with the recurrence and reminder contracts.

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
