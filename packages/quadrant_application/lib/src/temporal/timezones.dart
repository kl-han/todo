import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

/// Resolves an IANA timezone id against the bundled tz database, loading
/// the database on first use. Unknown ids are a domain validation failure
/// (→ 400), so both backends reject them identically.
tz.Location resolveTimezone(String id) {
  if (!_initialized) {
    tzdata.initializeTimeZones();
    _initialized = true;
  }
  try {
    return tz.getLocation(id);
  } on tz.LocationNotFoundException {
    throw DomainValidationError('Unknown timezone_id "$id".');
  }
}

/// Validates [schedule]'s timezone id against the tz database. Structural
/// consistency is already guaranteed by [TaskSchedule]'s constructor; this
/// adds the data-dependent check that the zone actually exists.
TaskSchedule validateScheduleTimezone(TaskSchedule schedule) {
  final id = schedule.timezoneId;
  if (id != null) resolveTimezone(id);
  return schedule;
}
