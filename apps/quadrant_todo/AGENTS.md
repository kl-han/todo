# Flutter app rules (apps/quadrant_todo)

- Widgets and `AppState` reach backends ONLY through `quadrant_api_client`;
  importing `quadrant_store` or SQLite here is prohibited.
- No business rules in widgets: quadrant derivation, validation, and
  versioning live behind the REST boundary.
- Mutations send `If-Match` when a version is known; a 412 means refresh
  to truth, never overwrite and never show a scary error.
- Transport failure is an explicit banner + retry; never fall back to a
  different dataset.
- Every deletion path must offer Undo (restore endpoint).
- Single-letter shortcuts must stay suppressed while text input has focus
  (`lib/platform/keyboard.dart`).
- Keep one widget tree for both platforms; divergence is limited to
  layout breakpoints (600lp matrix stack) and input conventions.
- Widget tests use `test/fake_backend.dart`; extend the fake in the same
  PR as any wire change.
- This package is intentionally outside the pub workspace; run
  `flutter pub get` / `flutter test` here with a local Flutter SDK.
