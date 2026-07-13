# prepare-release

Trigger: cutting vX.Y.0.

1. Confirm quality gates on main: analyze, all package tests, conformance
   (both harnesses), `sphinx-build -W`.
2. Bump versions together:
   - `docs/src/conf.py` (`version`, `release`),
   - `api/openapi.yaml` `info.version` (if the API surface moved),
   - pubspec versions when packages changed meaningfully.
3. Update `CHANGELOG.md` from the squash-commit log (one line per PR).
4. Build artifacts (see docs/src/devops/release-process.rst):
   `dart compile exe server/bin/quadrant_server.dart`, `flutter build
   linux --release`, `flutter build ipa` (macOS host).
5. Run the release-candidate validation checklist
   (references/rc-checklist.md) on real hardware; file and fix defects
   before tagging.
6. Verify backup/restore round-trip with `quadrant_server backup` (it
   self-verifies) and a restore drill.
7. Tag `vX.Y.0`; attach artifacts; note schema changes and the downgrade
   policy in the release notes.
