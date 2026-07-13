import 'package:quadrant_domain/quadrant_domain.dart' show PlainDate;
import 'package:quadrant_store/quadrant_store.dart';
import 'package:quadrant_usage/quadrant_usage.dart';
import 'package:test/test.dart';

void main() {
  late UsageDatabase db;
  late SqliteUsageRepository repository;

  setUp(() {
    db = UsageDatabase.inMemory();
    repository = SqliteUsageRepository(db);
  });

  tearDown(() => db.close());

  UsageInterval interval({
    String id = 'i1',
    String app = 'editor',
    DateTime? startedAt,
    int activeSeconds = 600,
    String? title,
  }) {
    final start = startedAt ?? DateTime.utc(2026, 7, 1, 12);
    return UsageInterval(
      id: id,
      deviceId: 'laptop',
      platform: 'linux',
      applicationId: app,
      applicationName: app,
      startedAt: start,
      endedAt: start.add(Duration(seconds: activeSeconds)),
      activeSeconds: activeSeconds,
      source: 'sway-ipc',
      windowTitle: title,
    );
  }

  test('usage.sqlite3 migrates independently of the vault schema', () {
    expect(usageSchemaVersion, 1);
  });

  test('intervals round-trip with null titles by default', () {
    repository.insertInterval(interval());
    final loaded = repository
        .intervalsBetween(
            DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 2))
        .single;
    expect(loaded.applicationId, 'editor');
    expect(loaded.activeSeconds, 600);
    expect(loaded.windowTitle, isNull);
    expect(loaded.source, 'sway-ipc');
  });

  test('daily merge upserts per (date, device, application)', () {
    final date = PlainDate.parse('2026-07-01');
    repository
      ..insertInterval(interval(id: 'a'))
      ..mergeIntoDaily(interval(id: 'a'), date)
      ..insertInterval(interval(id: 'b', activeSeconds: 300))
      ..mergeIntoDaily(interval(id: 'b', activeSeconds: 300), date);
    final daily = repository.dailyBetween(date, date).single;
    expect(daily.activeSeconds, 900);
    expect(daily.intervalCount, 2);
  });

  test('retention prunes raw intervals but never aggregates', () {
    final date = PlainDate.parse('2026-07-01');
    repository
      ..insertInterval(interval())
      ..mergeIntoDaily(interval(), date);
    final pruned =
        repository.pruneIntervalsBefore(DateTime.utc(2026, 7, 9));
    expect(pruned, 1);
    expect(
      repository.intervalsBetween(
          DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 2)),
      isEmpty,
    );
    expect(repository.dailyBetween(date, date), hasLength(1),
        reason: 'aggregates are retained long-term');
  });

  test('deleting a day removes its rows at both levels', () {
    final date = PlainDate.parse('2026-07-01');
    repository
      ..insertInterval(interval())
      ..mergeIntoDaily(interval(), date);
    repository.deleteDay(
        date, DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 2));
    expect(
      repository.intervalsBetween(
          DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 2)),
      isEmpty,
    );
    expect(repository.dailyBetween(date, date), isEmpty);
  });

  test('deleteAll drops the whole usage history', () {
    final date = PlainDate.parse('2026-07-01');
    repository
      ..insertInterval(interval())
      ..mergeIntoDaily(interval(), date);
    repository.deleteAll();
    expect(repository.dailyBetween(date, date), isEmpty);
  });
}
