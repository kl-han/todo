# Standalone server rules (server/)

- This package hosts; it does not define API behavior. Routes, DTOs, and
  rules live in `quadrant_api_server` and below — if a change here alters
  wire behavior, it is in the wrong place.
- Bearer auth is mandatory; `--allow-anonymous` stays development-only
  and must never gain a friendlier alias.
- Vault names are validated by `VaultManager.isValidName` BEFORE any path
  is formed; only `default` may auto-create.
- Vaults open strictly (no corruption auto-recovery) so operators notice;
  recovery guidance is restore-from-verified-backup.
- Keep the `quadrant_server listening on http://HOST:PORT` stdout line
  format stable — the conformance harness and tooling parse it.
- Backups go through `QuadrantDatabase.backupTo` + `verifySnapshot`;
  an unverified backup command exit(0) is a bug.
- Shutdown must remain clean under SIGINT/SIGTERM (cancel signal
  subscriptions, force-close connections, close vaults, remove pid file).
