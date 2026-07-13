import '../rules/validation.dart';

/// A calendar date with no time and no timezone (`2026-07-20`). Date-only
/// schedule values are stored and transported as plain dates — never as
/// midnight-UTC instants, which timezone conversion could move to the
/// preceding local date.
class PlainDate implements Comparable<PlainDate> {
  PlainDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > _daysInMonth(year, month)) {
      throw DomainValidationError('Invalid calendar date $this.');
    }
  }

  /// Strict `YYYY-MM-DD` parse; rejects impossible dates (Feb 30).
  factory PlainDate.parse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) {
      throw DomainValidationError('Date must be formatted YYYY-MM-DD.');
    }
    return PlainDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  /// The calendar date of [time], read in [time]'s own timezone.
  factory PlainDate.of(DateTime time) =>
      PlainDate(time.year, time.month, time.day);

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  static int _daysInMonth(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) return 29;
    return lengths[month - 1];
  }

  static bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  PlainDate addDays(int days) {
    final base = DateTime.utc(year, month, day).add(Duration(days: days));
    return PlainDate(base.year, base.month, base.day);
  }

  int differenceInDays(PlainDate other) => DateTime.utc(year, month, day)
      .difference(DateTime.utc(other.year, other.month, other.day))
      .inDays;

  @override
  int compareTo(PlainDate other) => differenceInDays(other);

  bool isAfter(PlainDate other) => compareTo(other) > 0;

  bool isBefore(PlainDate other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is PlainDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');

  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';
}
