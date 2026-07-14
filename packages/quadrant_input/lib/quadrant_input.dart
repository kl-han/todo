/// Inline metadata-entry parsing for Quadrant Todo task titles.
///
/// While a title is being edited (create or edit — the rules are
/// identical), `#` starts tag entry and `!` starts metadata (flag) entry,
/// each with autocomplete. These parsing rules are shared-UI behavior: no
/// platform may interpret `#` or `!` differently, so they live in one pure
/// package with no Flutter, HTTP, or SQLite dependency.
///
/// See `docs/src/product/task-behavior.rst` and
/// `docs/src/product/tag-behavior.rst`.
library;

export 'src/inline_entry.dart';
