import 'package:quadrant_domain/quadrant_domain.dart';

import '../recurrence/recurrence_rule.dart';
import '../recurrence/weekday.dart';

/// Generates occurrence dates for a rule, RFC 5545-style: candidates are
/// expanded per frequency period starting at [dtstart], then limited by
/// COUNT/UNTIL. Months lacking a BYMONTHDAY (the 31st in April) or an
/// ordinal weekday (a fifth Monday) contribute nothing — dates are
/// skipped, never clamped.
///
/// Everything is pure `PlainDate` calendar math; both backends and every
/// platform run exactly this code, which is what makes occurrence sets
/// identical everywhere.
class OccurrenceGenerator {
  OccurrenceGenerator(this.rule, this.dtstart);

  final RecurrenceRule rule;
  final PlainDate dtstart;

  /// All occurrence dates in `[from, to]` (inclusive). COUNT is counted
  /// from [dtstart], so earlier occurrences consume the budget even when
  /// the window starts later.
  List<PlainDate> between(PlainDate from, PlainDate to) {
    final result = <PlainDate>[];
    for (final date in _all()) {
      if (date.isAfter(to)) break;
      if (!date.isBefore(from)) result.add(date);
    }
    return result;
  }

  Iterable<PlainDate> _all() sync* {
    var emitted = 0;
    for (final candidate in _candidates()) {
      final until = rule.until;
      if (until != null && candidate.isAfter(until)) return;
      yield candidate;
      emitted += 1;
      final count = rule.count;
      if (count != null && emitted >= count) return;
    }
  }

  Iterable<PlainDate> _candidates() {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return _daily();
      case RecurrenceFrequency.weekly:
        return _weekly();
      case RecurrenceFrequency.monthly:
        return _monthly();
    }
  }

  Iterable<PlainDate> _daily() sync* {
    var date = dtstart;
    while (true) {
      yield date;
      date = date.addDays(rule.interval);
    }
  }

  Iterable<PlainDate> _weekly() sync* {
    final weekdays = rule.byWeekdays.isEmpty
        ? {Weekday.of(dtstart)}
        : {for (final day in rule.byWeekdays) day.weekday};
    // Weeks start on Monday; INTERVAL counts weeks from dtstart's week.
    final weekStart = dtstart.addDays(-(Weekday.of(dtstart).isoNumber - 1));
    var week = weekStart;
    while (true) {
      for (var offset = 0; offset < 7; offset++) {
        final date = week.addDays(offset);
        if (date.isBefore(dtstart)) continue;
        if (weekdays.contains(Weekday.of(date))) yield date;
      }
      week = week.addDays(7 * rule.interval);
    }
  }

  Iterable<PlainDate> _monthly() sync* {
    final monthDay = rule.byMonthDay ??
        (rule.byWeekdays.isEmpty ? dtstart.day : null);
    var year = dtstart.year;
    var month = dtstart.month;
    while (true) {
      final date = monthDay != null
          ? _byMonthDay(year, month, monthDay)
          : _byOrdinalWeekday(year, month, rule.byWeekdays.single);
      if (date != null && !date.isBefore(dtstart)) yield date;
      final next = month - 1 + rule.interval;
      year += next ~/ 12;
      month = next % 12 + 1;
    }
  }

  static PlainDate? _byMonthDay(int year, int month, int day) {
    try {
      return PlainDate(year, month, day);
    } on DomainValidationError {
      return null; // Month has no such day; skipped, not clamped.
    }
  }

  static PlainDate? _byOrdinalWeekday(int year, int month, ByWeekday byDay) {
    final matches = <PlainDate>[];
    for (var day = 1; day <= 31; day++) {
      final PlainDate date;
      try {
        date = PlainDate(year, month, day);
      } on DomainValidationError {
        break;
      }
      if (Weekday.of(date) == byDay.weekday) matches.add(date);
    }
    final ordinal = byDay.ordinal!;
    if (ordinal == -1) return matches.last;
    return ordinal <= matches.length ? matches[ordinal - 1] : null;
  }
}
