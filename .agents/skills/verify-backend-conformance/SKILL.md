# verify-backend-conformance

Trigger: before marking any PR ready; after touching anything under
`packages/quadrant_api_server`, `quadrant_store`, `quadrant_backend_host`,
or `server/`.

```bash
export PATH="$PATH:<dart-sdk>/bin"
dart pub get
dart analyze --fatal-infos
(cd packages/quadrant_conformance && dart test --reporter=expanded)
```

Interpretation:

- `embedded_conformance_test.dart` runs the contract against the real
  backend isolate in-process.
- `standalone_conformance_test.dart` launches
  `server/bin/quadrant_server.dart` as a subprocess (`--port 0`, fresh
  temp `--data-dir`, generated token) and parses its "listening on" line.
- A test passing on one harness and failing on the other is the exact
  defect class this suite exists for: a local/remote behavioral
  divergence. Fix the shared handler or store — never fork behavior per
  backend.
- New API behavior that isn't asserted here does not exist; add it to
  `lib/src/suite.dart` in the same PR (tests share one live backend, so
  only touch entities the test itself created).
