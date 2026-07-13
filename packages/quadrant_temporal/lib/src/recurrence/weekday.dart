import 'package:quadrant_domain/quadrant_domain.dart';

/// ISO weekday with the RFC 5545 two-letter code.
enum Weekday {
  monday('MO', DateTime.monday),
  tuesday('TU', DateTime.tuesday),
  wednesday('WE', DateTime.wednesday),
  thursday('TH', DateTime.thursday),
  friday('FR', DateTime.friday),
  saturday('SA', DateTime.saturday),
  sunday('SU', DateTime.sunday);

  const Weekday(this.rfcCode, this.isoNumber);

  /// RFC 5545 BYDAY code (`MO`..`SU`).
  final String rfcCode;

  /// ISO 8601 weekday number (Monday = 1 .. Sunday = 7), matching
  /// `DateTime.weekday`.
  final int isoNumber;

  static Weekday fromRfc(String code) => values.firstWhere(
        (day) => day.rfcCode == code,
        orElse: () =>
            throw DomainValidationError('Unknown BYDAY weekday "$code".'),
      );

  static Weekday of(PlainDate date) => values.firstWhere((day) =>
      day.isoNumber ==
      DateTime.utc(date.year, date.month, date.day).weekday);
}
