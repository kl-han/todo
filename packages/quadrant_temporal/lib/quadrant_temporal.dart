/// Temporal engine for Quadrant Todo: the RFC 5545-subset recurrence rule
/// model and date-based occurrence generation.
///
/// Pure calendar math over `PlainDate`; nothing here depends on HTTP,
/// SQLite, Flutter, or the tz database (wall-time → instant conversion
/// stays in the application layer, next to the tz data).
library;

export 'src/occurrence_generation/occurrence_generator.dart';
export 'src/recurrence/recurrence_rule.dart';
export 'src/recurrence/weekday.dart';
