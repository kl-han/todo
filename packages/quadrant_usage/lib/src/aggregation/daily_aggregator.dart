import 'package:quadrant_domain/quadrant_domain.dart' show PlainDate;

import '../intervals/usage_interval.dart';

/// One day × device × application rollup — the only shape retained
/// long-term and the only shape ever eligible for remote upload.
class DailyUsage {
  const DailyUsage({
    required this.date,
    required this.deviceId,
    required this.applicationId,
    this.categoryId,
    this.activeSeconds = 0,
    this.idleSeconds = 0,
    this.focusSessionSeconds = 0,
    this.intervalCount = 0,
  });

  final PlainDate date;
  final String deviceId;
  final String applicationId;
  final String? categoryId;
  final int activeSeconds;
  final int idleSeconds;
  final int focusSessionSeconds;
  final int intervalCount;

  DailyUsage merge(UsageInterval interval) => DailyUsage(
        date: date,
        deviceId: deviceId,
        applicationId: applicationId,
        categoryId: categoryId ?? interval.categoryId,
        activeSeconds: activeSeconds + interval.activeSeconds,
        idleSeconds: idleSeconds + interval.idleSeconds,
        focusSessionSeconds: focusSessionSeconds,
        intervalCount: intervalCount + 1,
      );
}

/// Rolls raw intervals up by local calendar date. [localDateOf] maps the
/// interval's wall start to the device-local date (the tz conversion
/// lives with the caller, next to the tz database).
List<DailyUsage> aggregateDaily(
  Iterable<UsageInterval> intervals,
  PlainDate Function(DateTime startedAt) localDateOf,
) {
  final byKey = <(String, String, String), DailyUsage>{};
  for (final interval in intervals) {
    final date = localDateOf(interval.startedAt);
    final key = (date.toString(), interval.deviceId, interval.applicationId);
    final existing = byKey[key] ??
        DailyUsage(
          date: date,
          deviceId: interval.deviceId,
          applicationId: interval.applicationId,
        );
    byKey[key] = existing.merge(interval);
  }
  final result = byKey.values.toList()
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byDevice = a.deviceId.compareTo(b.deviceId);
      if (byDevice != 0) return byDevice;
      return a.applicationId.compareTo(b.applicationId);
    });
  return result;
}
