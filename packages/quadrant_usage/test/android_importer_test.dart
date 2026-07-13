import 'package:quadrant_usage/quadrant_usage.dart';
import 'package:test/test.dart';

void main() {
  const base = 1782000000000; // fixed epoch anchor

  AndroidUsageEvent event(
    int offsetSeconds,
    AndroidEventType type, [
    String package = 'org.app.a',
  ]) =>
      AndroidUsageEvent(
        packageName: package,
        type: type,
        timestampMs: base + offsetSeconds * 1000,
      );

  AndroidUsageImporter importer({PrivacyPolicy? policy}) =>
      AndroidUsageImporter(
        deviceId: 'phone',
        policy:
            policy ?? const PrivacyPolicy(trackingEnabled: true),
      );

  test('resume/pause pairs become derived intervals', () {
    final result = importer().import([
      event(0, AndroidEventType.activityResumed),
      event(300, AndroidEventType.activityPaused),
      event(300, AndroidEventType.activityResumed, 'org.app.b'),
      event(360, AndroidEventType.activityPaused, 'org.app.b'),
    ], watermarkMs: 0);
    expect(
      result.intervals.map((i) => (i.applicationId, i.activeSeconds)),
      [('org.app.a', 300), ('org.app.b', 60)],
    );
    expect(result.intervals.first.confidence, 'derived');
    expect(result.intervals.first.platform, 'android');
    expect(result.nextWatermarkMs, base + 360000);
  });

  test('screen-off and shutdown close spans; interactive alone opens '
      'nothing', () {
    final result = importer().import([
      event(0, AndroidEventType.activityResumed),
      event(120, AndroidEventType.screenNonInteractive),
      event(600, AndroidEventType.screenInteractive),
      event(660, AndroidEventType.activityResumed),
      event(720, AndroidEventType.deviceShutdown),
    ], watermarkMs: 0);
    expect(
      result.intervals.map((i) => i.activeSeconds),
      [120, 60],
      reason: 'screen-off and locked periods are excluded',
    );
  });

  test('a lost pause is repaired by the next resume', () {
    final result = importer().import([
      event(0, AndroidEventType.activityResumed, 'org.app.a'),
      // The pause for app.a never arrived (vendor stream gap).
      event(180, AndroidEventType.activityResumed, 'org.app.b'),
      event(240, AndroidEventType.activityPaused, 'org.app.b'),
    ], watermarkMs: 0);
    expect(
      result.intervals.map((i) => (i.applicationId, i.activeSeconds)),
      [('org.app.a', 180), ('org.app.b', 60)],
    );
  });

  test('unmatched pauses and unknown event kinds are ignored', () {
    expect(AndroidEventType.fromAndroid(999), isNull);
    final result = importer().import([
      event(0, AndroidEventType.activityPaused, 'org.app.ghost'),
    ], watermarkMs: 0);
    expect(result.intervals, isEmpty);
  });

  test('overlapping re-imports are idempotent via the watermark', () {
    final batch = [
      event(0, AndroidEventType.activityResumed),
      event(300, AndroidEventType.activityPaused),
    ];
    final first = importer().import(batch, watermarkMs: 0);
    expect(first.intervals, hasLength(1));
    // WorkManager re-delivers the same events hours later, plus one new
    // pair — only the new pair imports.
    final second = importer().import([
      ...batch,
      event(600, AndroidEventType.activityResumed),
      event(660, AndroidEventType.activityPaused),
    ], watermarkMs: first.nextWatermarkMs);
    expect(second.intervals, hasLength(1));
    expect(second.intervals.single.activeSeconds, 60);
  });

  test('a span still open at batch end re-imports completely later', () {
    final first = importer().import([
      event(0, AndroidEventType.activityResumed),
      event(300, AndroidEventType.activityPaused),
      event(600, AndroidEventType.activityResumed),
      // No closing event yet — the user is still in the app.
    ], watermarkMs: 0);
    expect(first.intervals, hasLength(1));

    final second = importer().import([
      event(600, AndroidEventType.activityResumed),
      event(900, AndroidEventType.activityPaused),
    ], watermarkMs: first.nextWatermarkMs);
    expect(second.intervals.single.activeSeconds, 300,
        reason: 'the open span was deferred, not lost or duplicated');
  });

  test('out-of-order delivery is sorted before processing', () {
    final result = importer().import([
      event(300, AndroidEventType.activityPaused),
      event(0, AndroidEventType.activityResumed),
    ], watermarkMs: 0);
    expect(result.intervals.single.activeSeconds, 300);
  });

  test('revoked access (empty batches) produces nothing and keeps the '
      'watermark', () {
    final result = importer().import(const [], watermarkMs: 42);
    expect(result.intervals, isEmpty);
    expect(result.nextWatermarkMs, 42);
  });

  test('the privacy policy applies to imports too', () {
    final result = importer(
      policy: const PrivacyPolicy(
        trackingEnabled: true,
        excludedApplicationIds: {'org.app.private'},
      ),
    ).import([
      event(0, AndroidEventType.activityResumed, 'org.app.private'),
      event(300, AndroidEventType.activityPaused, 'org.app.private'),
      event(300, AndroidEventType.activityResumed),
      event(360, AndroidEventType.activityPaused),
    ], watermarkMs: 0);
    expect(result.intervals.map((i) => i.applicationId), ['org.app.a']);
  });
}
