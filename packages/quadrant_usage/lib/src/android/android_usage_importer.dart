import 'package:quadrant_domain/quadrant_domain.dart' show EntityId;

import '../intervals/usage_interval.dart';
import '../privacy/privacy_policy.dart';

/// The `UsageStatsManager` event kinds the importer understands. Values
/// mirror `android.app.usage.UsageEvents.Event` constants so the platform
/// adapter can pass them through unmapped.
enum AndroidEventType {
  activityResumed(1), // MOVE_TO_FOREGROUND / ACTIVITY_RESUMED
  activityPaused(2), // MOVE_TO_BACKGROUND / ACTIVITY_PAUSED
  screenInteractive(15),
  screenNonInteractive(16),
  deviceShutdown(26);

  const AndroidEventType(this.androidValue);

  final int androidValue;

  static AndroidEventType? fromAndroid(int value) {
    for (final type in values) {
      if (type.androidValue == value) return type;
    }
    return null; // Unknown kinds are ignored, never an error.
  }
}

/// One raw event as handed over by the platform adapter.
class AndroidUsageEvent {
  const AndroidUsageEvent({
    required this.packageName,
    required this.type,
    required this.timestampMs,
  });

  final String packageName;
  final AndroidEventType type;

  /// Epoch milliseconds (the unit `UsageEvents` uses).
  final int timestampMs;
}

/// The result of one import batch: closed intervals plus the new
/// watermark to persist for the next query.
class AndroidImportResult {
  const AndroidImportResult({
    required this.intervals,
    required this.nextWatermarkMs,
  });

  final List<UsageInterval> intervals;

  /// Query `UsageStatsManager` from this timestamp next time. Re-importing
  /// an overlapping batch is safe: events at or before the previous
  /// watermark are skipped, so delayed WorkManager runs and the
  /// re-import-on-open both stay idempotent.
  final int nextWatermarkMs;
}

/// Converts a `UsageStatsManager` event batch into usage intervals —
/// pure, deterministic, and shared by every Android build, so the
/// platform adapter stays a thin pass-through.
///
/// Rules ("Android limitations" in the design doc are embraced, not
/// fought): screen-off and shutdown close the current span; an
/// unmatched pause is ignored; a resume with another app still open
/// closes the previous app first (vendor streams lose pauses); events
/// are processed in timestamp order regardless of input order;
/// intervals are marked `confidence: derived` because the OS history is
/// not an exact observation.
class AndroidUsageImporter {
  AndroidUsageImporter({
    required this.deviceId,
    PrivacyPolicy policy = const PrivacyPolicy(),
  }) : _policy = policy;

  final String deviceId;
  final PrivacyPolicy _policy;

  AndroidImportResult import(
    List<AndroidUsageEvent> events, {
    required int watermarkMs,
  }) {
    final sorted = [...events]
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    final intervals = <UsageInterval>[];
    var nextWatermark = watermarkMs;

    String? openPackage;
    int? openSinceMs;

    void close(int atMs) {
      final package = openPackage;
      final since = openSinceMs;
      openPackage = null;
      openSinceMs = null;
      if (package == null || since == null) return;
      final seconds = (atMs - since) ~/ 1000;
      if (seconds <= 0) return;
      final startedAt =
          DateTime.fromMillisecondsSinceEpoch(since, isUtc: true);
      intervals.add(UsageInterval(
        id: EntityId.generate(),
        deviceId: deviceId,
        platform: 'android',
        applicationId: package,
        applicationName: package,
        startedAt: startedAt,
        endedAt: DateTime.fromMillisecondsSinceEpoch(atMs, isUtc: true),
        activeSeconds: seconds,
        source: 'usage-stats',
        confidence: 'derived',
      ));
    }

    for (final event in sorted) {
      if (event.timestampMs <= watermarkMs) continue; // already imported
      nextWatermark =
          event.timestampMs > nextWatermark ? event.timestampMs : nextWatermark;
      switch (event.type) {
        case AndroidEventType.activityResumed:
          if (openPackage == event.packageName) break; // duplicate resume
          close(event.timestampMs);
          final at = DateTime.fromMillisecondsSinceEpoch(event.timestampMs,
              isUtc: true);
          if (_policy.allowsRecording(event.packageName, at)) {
            openPackage = event.packageName;
            openSinceMs = event.timestampMs;
          }
        case AndroidEventType.activityPaused:
          if (openPackage == event.packageName) close(event.timestampMs);
          // An unmatched pause (missed resume) is silently ignored.
        case AndroidEventType.screenNonInteractive:
        case AndroidEventType.deviceShutdown:
          close(event.timestampMs);
        case AndroidEventType.screenInteractive:
          break; // recording restarts on the next resume, never here
      }
    }
    // A still-open span is NOT emitted: it re-imports completely once its
    // pause/screen-off event exists, keeping partial batches loss-free.
    return AndroidImportResult(
      intervals: intervals,
      nextWatermarkMs:
          openSinceMs != null ? openSinceMs! - 1 : nextWatermark,
    );
  }
}
