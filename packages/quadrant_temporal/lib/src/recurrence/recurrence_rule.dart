import 'package:quadrant_domain/quadrant_domain.dart';

import 'weekday.dart';

/// Recurrence frequency; the supported RFC 5545 subset.
enum RecurrenceFrequency {
  daily('DAILY'),
  weekly('WEEKLY'),
  monthly('MONTHLY');

  const RecurrenceFrequency(this.rfcName);

  final String rfcName;

  static RecurrenceFrequency fromRfc(String value) => values.firstWhere(
        (freq) => freq.rfcName == value,
        orElse: () =>
            throw DomainValidationError('Unsupported FREQ "$value".'),
      );
}

/// One BYDAY part: a weekday with an optional monthly ordinal
/// (`2TU` = second Tuesday, `-1FR` = last Friday).
class ByWeekday {
  const ByWeekday(this.weekday, [this.ordinal]);

  final Weekday weekday;

  /// 1..4 or -1 (last); null means "every" (weekly rules).
  final int? ordinal;

  @override
  bool operator ==(Object other) =>
      other is ByWeekday &&
      other.weekday == weekday &&
      other.ordinal == ordinal;

  @override
  int get hashCode => Object.hash(weekday, ordinal);

  @override
  String toString() => '${ordinal ?? ''}${weekday.rfcCode}';
}

/// A validated recurrence rule — the RFC 5545 RRULE subset the product
/// supports (see `api/openapi.yaml`). Parse with [RecurrenceRule.parse];
/// [toRrule] emits the canonical serialization stored in the database.
class RecurrenceRule {
  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.byWeekdays = const [],
    this.byMonthDay,
    this.count,
    this.until,
  }) {
    if (interval < 1) {
      throw DomainValidationError('INTERVAL must be at least 1.');
    }
    if (count != null && until != null) {
      throw DomainValidationError('COUNT and UNTIL are mutually exclusive.');
    }
    if (count != null && count! < 1) {
      throw DomainValidationError('COUNT must be at least 1.');
    }
    switch (frequency) {
      case RecurrenceFrequency.daily:
        if (byWeekdays.isNotEmpty || byMonthDay != null) {
          throw DomainValidationError(
            'FREQ=DAILY takes neither BYDAY nor BYMONTHDAY.',
          );
        }
      case RecurrenceFrequency.weekly:
        if (byMonthDay != null) {
          throw DomainValidationError('FREQ=WEEKLY takes no BYMONTHDAY.');
        }
        if (byWeekdays.any((day) => day.ordinal != null)) {
          throw DomainValidationError(
            'Weekly BYDAY entries take no ordinal.',
          );
        }
      case RecurrenceFrequency.monthly:
        if (byMonthDay != null && byWeekdays.isNotEmpty) {
          throw DomainValidationError(
            'FREQ=MONTHLY takes BYDAY or BYMONTHDAY, not both.',
          );
        }
        if (byMonthDay != null && (byMonthDay! < 1 || byMonthDay! > 31)) {
          throw DomainValidationError('BYMONTHDAY must be 1..31.');
        }
        if (byWeekdays.length > 1) {
          throw DomainValidationError(
            'Monthly BYDAY supports a single ordinal weekday.',
          );
        }
        if (byWeekdays.isNotEmpty) {
          final ordinal = byWeekdays.single.ordinal;
          if (ordinal == null || ordinal == 0 || ordinal > 4 || ordinal < -1) {
            throw DomainValidationError(
              'Monthly BYDAY ordinal must be 1..4 or -1 (last).',
            );
          }
        }
    }
  }

  /// Parses the canonical `KEY=VALUE;...` form, e.g.
  /// `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR;COUNT=10`.
  factory RecurrenceRule.parse(String rrule) {
    RecurrenceFrequency? frequency;
    var interval = 1;
    var byWeekdays = const <ByWeekday>[];
    int? byMonthDay;
    int? count;
    PlainDate? until;

    if (rrule.trim().isEmpty) {
      throw DomainValidationError('rrule must not be empty.');
    }
    for (final part in rrule.trim().split(';')) {
      if (part.isEmpty) continue;
      final pieces = part.split('=');
      if (pieces.length != 2) {
        throw DomainValidationError('Malformed RRULE part "$part".');
      }
      final [key, value] = pieces;
      switch (key.toUpperCase()) {
        case 'FREQ':
          frequency = RecurrenceFrequency.fromRfc(value.toUpperCase());
        case 'INTERVAL':
          interval = _int(value, 'INTERVAL');
        case 'BYDAY':
          byWeekdays = [
            for (final token in value.toUpperCase().split(','))
              _parseByDay(token),
          ];
        case 'BYMONTHDAY':
          byMonthDay = _int(value, 'BYMONTHDAY');
        case 'COUNT':
          count = _int(value, 'COUNT');
        case 'UNTIL':
          until = _parseUntil(value);
        default:
          throw DomainValidationError('Unsupported RRULE part "$key".');
      }
    }
    if (frequency == null) {
      throw DomainValidationError('RRULE requires FREQ.');
    }
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      byWeekdays: byWeekdays,
      byMonthDay: byMonthDay,
      count: count,
      until: until,
    );
  }

  final RecurrenceFrequency frequency;
  final int interval;
  final List<ByWeekday> byWeekdays;
  final int? byMonthDay;
  final int? count;
  final PlainDate? until;

  /// Canonical serialization; `parse(rule.toRrule())` is the identity.
  String toRrule() {
    final parts = ['FREQ=${frequency.rfcName}'];
    if (interval != 1) parts.add('INTERVAL=$interval');
    if (byWeekdays.isNotEmpty) {
      parts.add('BYDAY=${byWeekdays.join(',')}');
    }
    if (byMonthDay != null) parts.add('BYMONTHDAY=$byMonthDay');
    if (count != null) parts.add('COUNT=$count');
    final untilDate = until;
    if (untilDate != null) {
      String pad(int n, int w) => n.toString().padLeft(w, '0');
      parts.add('UNTIL=${pad(untilDate.year, 4)}'
          '${pad(untilDate.month, 2)}${pad(untilDate.day, 2)}');
    }
    return parts.join(';');
  }

  static int _int(String value, String key) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw DomainValidationError('$key must be an integer.');
    }
    return parsed;
  }

  static ByWeekday _parseByDay(String token) {
    final match = RegExp(r'^(-?\d+)?(MO|TU|WE|TH|FR|SA|SU)$').firstMatch(token);
    if (match == null) {
      throw DomainValidationError('Malformed BYDAY entry "$token".');
    }
    final ordinal = match[1] == null ? null : int.parse(match[1]!);
    return ByWeekday(Weekday.fromRfc(match[2]!), ordinal);
  }

  static PlainDate _parseUntil(String value) {
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(value);
    if (match == null) {
      throw DomainValidationError('UNTIL must be a YYYYMMDD date.');
    }
    return PlainDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }
}
