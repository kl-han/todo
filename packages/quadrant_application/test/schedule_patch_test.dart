import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

void main() {
  final dueDate = TaskSchedule(
    dueKind: ScheduleKind.date,
    dueDate: PlainDate.parse('2026-07-20'),
  );
  final dueInstant = TaskSchedule(
    dueKind: ScheduleKind.datetime,
    dueAtUtc: DateTime.utc(2026, 7, 20, 20),
    timezoneId: 'America/Chicago',
  );

  group('SchedulePatch.applyTo', () {
    test('empty patch keeps the schedule unchanged', () {
      final merged = const SchedulePatch().applyTo(dueInstant);
      expect(merged.dueAtUtc, dueInstant.dueAtUtc);
      expect(merged.timezoneId, 'America/Chicago');
    });

    test('providing a kind resets that side to the provided values', () {
      // date -> datetime without an instant must fail, not keep the date.
      expect(
        () => const SchedulePatch(dueKind: ScheduleKind.datetime)
            .applyTo(dueDate),
        throwsA(isA<DomainValidationError>()),
      );
      final merged = SchedulePatch(
        dueKind: ScheduleKind.datetime,
        dueAtUtc: DateTime.utc(2026, 7, 21, 9),
        timezoneId: 'America/Chicago',
      ).applyTo(dueDate);
      expect(merged.dueKind, ScheduleKind.datetime);
      expect(merged.dueDate, isNull);
    });

    test('providing a value without its kind updates under the same kind',
        () {
      final merged = SchedulePatch(dueDate: PlainDate.parse('2026-08-01'))
          .applyTo(dueDate);
      expect(merged.dueKind, ScheduleKind.date);
      expect(merged.dueDate, PlainDate.parse('2026-08-01'));
    });

    test('kind none clears the side', () {
      final merged =
          const SchedulePatch(dueKind: ScheduleKind.none).applyTo(dueInstant);
      expect(merged.isScheduled, isFalse);
      expect(merged.dueAtUtc, isNull);
    });

    test('losing the last datetime side sheds the timezone', () {
      final merged = SchedulePatch(
        dueKind: ScheduleKind.date,
        dueDate: PlainDate.parse('2026-07-20'),
      ).applyTo(dueInstant);
      expect(merged.timezoneId, isNull);
    });

    test('patching one side leaves the other side alone', () {
      final both = TaskSchedule(
        startKind: ScheduleKind.date,
        startDate: PlainDate.parse('2026-07-01'),
        dueKind: ScheduleKind.datetime,
        dueAtUtc: DateTime.utc(2026, 7, 20, 20),
        timezoneId: 'America/Chicago',
      );
      final merged = SchedulePatch(
        startDate: PlainDate.parse('2026-07-02'),
      ).applyTo(both);
      expect(merged.startDate, PlainDate.parse('2026-07-02'));
      expect(merged.dueAtUtc, both.dueAtUtc);
      expect(merged.timezoneId, 'America/Chicago');
    });
  });

  group('timezone validation', () {
    test('accepts real IANA ids and rejects unknown ones', () {
      expect(validateScheduleTimezone(dueInstant), dueInstant);
      expect(
        () => validateScheduleTimezone(TaskSchedule(
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 7, 20, 20),
          timezoneId: 'Mars/Olympus_Mons',
        )),
        throwsA(isA<DomainValidationError>()),
      );
    });
  });
}
