import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:quadrant_temporal/quadrant_temporal.dart';
import 'package:test/test.dart';

PlainDate d(String value) => PlainDate.parse(value);

List<String> generate(String rrule, String dtstart, String from, String to) =>
    OccurrenceGenerator(RecurrenceRule.parse(rrule), d(dtstart))
        .between(d(from), d(to))
        .map((date) => date.toString())
        .toList();

void main() {
  group('RRULE codec', () {
    test('parse → serialize is canonical and stable', () {
      for (final rrule in [
        'FREQ=DAILY',
        'FREQ=DAILY;INTERVAL=3',
        'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU',
        'FREQ=MONTHLY;BYMONTHDAY=31',
        'FREQ=MONTHLY;BYDAY=2TU',
        'FREQ=MONTHLY;BYDAY=-1FR;COUNT=6',
        'FREQ=DAILY;UNTIL=20261231',
      ]) {
        expect(RecurrenceRule.parse(rrule).toRrule(), rrule);
      }
    });

    test('rejects malformed and unsupported rules', () {
      for (final rrule in [
        '',
        'FREQ=YEARLY',
        'INTERVAL=2', // no FREQ
        'FREQ=DAILY;BYDAY=MO', // BYDAY on daily
        'FREQ=WEEKLY;BYDAY=2TU', // ordinal on weekly
        'FREQ=MONTHLY;BYDAY=MO', // monthly BYDAY needs an ordinal
        'FREQ=MONTHLY;BYDAY=5MO', // ordinal out of range
        'FREQ=MONTHLY;BYMONTHDAY=32',
        'FREQ=MONTHLY;BYMONTHDAY=15;BYDAY=2TU',
        'FREQ=DAILY;COUNT=3;UNTIL=20261231',
        'FREQ=DAILY;INTERVAL=0',
        'FREQ=DAILY;UNTIL=2026-12-31', // wrong UNTIL shape
        'FREQ=DAILY;RANDOM=1',
      ]) {
        expect(() => RecurrenceRule.parse(rrule),
            throwsA(isA<DomainValidationError>()),
            reason: rrule);
      }
    });
  });

  group('generation', () {
    test('daily with interval', () {
      expect(
        generate('FREQ=DAILY;INTERVAL=3', '2026-07-01', '2026-07-01',
            '2026-07-10'),
        ['2026-07-01', '2026-07-04', '2026-07-07', '2026-07-10'],
      );
    });

    test('weekly defaults to the dtstart weekday', () {
      // 2026-07-01 is a Wednesday.
      expect(
        generate('FREQ=WEEKLY', '2026-07-01', '2026-07-01', '2026-07-20'),
        ['2026-07-01', '2026-07-08', '2026-07-15'],
      );
    });

    test('weekly on selected weekdays never emits before dtstart', () {
      // 2026-07-01 is a Wednesday; the Monday of that week (06-29) is
      // before dtstart and must not appear.
      expect(
        generate('FREQ=WEEKLY;BYDAY=MO,FR', '2026-07-01', '2026-06-29',
            '2026-07-14'),
        ['2026-07-03', '2026-07-06', '2026-07-10', '2026-07-13'],
      );
    });

    test('weekdays pattern', () {
      expect(
        generate('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR', '2026-07-06',
            '2026-07-06', '2026-07-12'),
        [
          '2026-07-06', '2026-07-07', '2026-07-08', '2026-07-09',
          '2026-07-10',
        ],
      );
    });

    test('biweekly INTERVAL counts weeks from the dtstart week', () {
      expect(
        generate('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO', '2026-07-06',
            '2026-07-01', '2026-08-04'),
        ['2026-07-06', '2026-07-20', '2026-08-03'],
      );
    });

    test('monthly on the 31st skips short months (never clamps)', () {
      expect(
        generate('FREQ=MONTHLY;BYMONTHDAY=31', '2026-01-31', '2026-01-01',
            '2026-06-30'),
        ['2026-01-31', '2026-03-31', '2026-05-31'],
      );
    });

    test('monthly on the 29th skips February in non-leap years only', () {
      expect(
        generate('FREQ=MONTHLY;BYMONTHDAY=29', '2027-01-29', '2027-01-01',
            '2027-03-31'),
        ['2027-01-29', '2027-03-29'], // 2027 is not a leap year
      );
      expect(
        generate('FREQ=MONTHLY;BYMONTHDAY=29', '2028-01-29', '2028-01-01',
            '2028-03-31'),
        ['2028-01-29', '2028-02-29', '2028-03-29'], // 2028 is
      );
    });

    test('monthly by ordinal weekday, including last', () {
      // Second Tuesday of each month.
      expect(
        generate('FREQ=MONTHLY;BYDAY=2TU', '2026-07-01', '2026-07-01',
            '2026-09-30'),
        ['2026-07-14', '2026-08-11', '2026-09-08'],
      );
      // Last Friday.
      expect(
        generate('FREQ=MONTHLY;BYDAY=-1FR', '2026-07-01', '2026-07-01',
            '2026-08-31'),
        ['2026-07-31', '2026-08-28'],
      );
    });

    test('COUNT is consumed from dtstart, not from the window', () {
      // 5 daily occurrences total; a window starting later sees only the
      // remainder.
      expect(
        generate('FREQ=DAILY;COUNT=5', '2026-07-01', '2026-07-03',
            '2026-07-31'),
        ['2026-07-03', '2026-07-04', '2026-07-05'],
      );
    });

    test('UNTIL is inclusive', () {
      expect(
        generate('FREQ=DAILY;UNTIL=20260703', '2026-07-01', '2026-07-01',
            '2026-07-31'),
        ['2026-07-01', '2026-07-02', '2026-07-03'],
      );
    });

    test('monthly by date defaults to the dtstart day', () {
      expect(
        generate('FREQ=MONTHLY', '2026-07-15', '2026-07-01', '2026-09-30'),
        ['2026-07-15', '2026-08-15', '2026-09-15'],
      );
    });
  });
}
