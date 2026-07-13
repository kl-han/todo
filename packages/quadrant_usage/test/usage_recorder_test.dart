import 'package:quadrant_domain/quadrant_domain.dart' show PlainDate;
import 'package:quadrant_usage/quadrant_usage.dart';
import 'package:test/test.dart';

void main() {
  late List<UsageInterval> closed;
  late UsageRecorder recorder;

  DateTime wall(int minutes) => DateTime.utc(2026, 7, 1, 12, minutes);
  int mono(int minutes) => minutes * 60 * 1000;

  UsageRecorder build({PrivacyPolicy? policy}) => UsageRecorder(
        deviceId: 'laptop',
        platform: 'linux',
        source: 'sway-ipc',
        policy: policy ??
            const PrivacyPolicy(trackingEnabled: true),
        onIntervalClosed: closed.add,
      );

  FocusChanged focus(int minutes, String app, {String? title}) =>
      FocusChanged(
        at: wall(minutes),
        monotonicMs: mono(minutes),
        applicationId: app,
        applicationName: app,
        windowTitle: title,
      );

  setUp(() {
    closed = [];
    recorder = build();
  });

  group('event state machine', () {
    test('a focus change closes the previous interval and opens the next',
        () {
      recorder.handle(focus(0, 'editor'));
      recorder.handle(focus(10, 'browser'));
      recorder.handle(focus(15, 'editor'));
      expect(closed.map((i) => (i.applicationId, i.activeSeconds)),
          [('editor', 600), ('browser', 300)]);
      expect(recorder.hasOpenInterval, isTrue);
    });

    test('idle closes; resume reopens the same application', () {
      recorder.handle(focus(0, 'editor'));
      recorder.handle(IdleStarted(at: wall(10), monotonicMs: mono(10)));
      expect(closed.single.activeSeconds, 600);
      recorder
          .handle(ActivityResumed(at: wall(20), monotonicMs: mono(20)));
      recorder.handle(focus(25, 'browser'));
      expect(closed[1].applicationId, 'editor');
      expect(closed[1].activeSeconds, 300,
          reason: 'the idle gap must not count');
    });

    test('lock closes; recording waits for the next focus after unlock',
        () {
      recorder.handle(focus(0, 'editor'));
      recorder.handle(SessionBlanked(at: wall(10), monotonicMs: mono(10)));
      expect(closed.single.activeSeconds, 600);
      recorder
          .handle(SessionRestored(at: wall(30), monotonicMs: mono(30)));
      expect(recorder.hasOpenInterval, isFalse,
          reason: 'no speculation about post-unlock focus');
      recorder.handle(focus(31, 'editor'));
      expect(recorder.hasOpenInterval, isTrue);
    });

    test('collector stop closes the interval safely', () {
      recorder.handle(focus(0, 'editor'));
      recorder
          .handle(CollectorStopped(at: wall(5), monotonicMs: mono(5)));
      expect(closed.single.activeSeconds, 300);
      expect(recorder.hasOpenInterval, isFalse);
    });

    test('durations come from the monotonic clock: a wall clock moving '
        'backward cannot distort them', () {
      recorder.handle(focus(0, 'editor'));
      // Wall clock jumps back an hour; monotonic keeps going.
      recorder.handle(FocusChanged(
        at: DateTime.utc(2026, 7, 1, 11, 10),
        monotonicMs: mono(10),
        applicationId: 'browser',
      ));
      expect(closed.single.activeSeconds, 600);
    });

    test('sub-second focus flicker never becomes a record', () {
      recorder.handle(focus(0, 'editor'));
      recorder.handle(FocusChanged(
        at: wall(0),
        monotonicMs: mono(0) + 400,
        applicationId: 'browser',
      ));
      expect(closed, isEmpty);
    });
  });

  group('privacy', () {
    test('tracking is off by default: nothing is recorded', () {
      recorder = build(policy: const PrivacyPolicy());
      recorder.handle(focus(0, 'editor'));
      recorder.handle(focus(10, 'browser'));
      expect(closed, isEmpty);
    });

    test('window titles stay null unless explicitly opted in', () {
      recorder.handle(focus(0, 'editor', title: 'secret-plan.md'));
      recorder.handle(focus(10, 'browser'));
      expect(closed.single.windowTitle, isNull);

      recorder = build(
        policy: const PrivacyPolicy(
          trackingEnabled: true,
          collectWindowTitles: true,
        ),
      );
      recorder.handle(focus(20, 'editor', title: 'notes.md'));
      recorder.handle(focus(30, 'browser'));
      expect(closed.last.windowTitle, 'notes.md');
    });

    test('an excluded application never enters intervals', () {
      recorder = build(
        policy: const PrivacyPolicy(
          trackingEnabled: true,
          excludedApplicationIds: {'signal'},
        ),
      );
      recorder.handle(focus(0, 'signal'));
      recorder.handle(focus(10, 'editor'));
      recorder.handle(focus(20, 'signal'));
      recorder.handle(focus(30, 'editor'));
      expect(closed.map((i) => i.applicationId), ['editor']);
    });

    test('private mode closes the current interval immediately', () {
      recorder.handle(focus(0, 'editor'));
      recorder.updatePolicy(
        const PrivacyPolicy(trackingEnabled: true, privateMode: true),
        at: wall(7),
        monotonicMs: mono(7),
      );
      expect(closed.single.activeSeconds, 420);
      recorder.handle(focus(8, 'browser'));
      expect(recorder.hasOpenInterval, isFalse);
    });

    test('turning private mode off resumes on the remembered focus', () {
      recorder.handle(focus(0, 'editor'));
      recorder.updatePolicy(
        const PrivacyPolicy(trackingEnabled: true, privateMode: true),
        at: wall(5),
        monotonicMs: mono(5),
      );
      recorder.updatePolicy(
        const PrivacyPolicy(trackingEnabled: true),
        at: wall(9),
        monotonicMs: mono(9),
      );
      recorder.handle(focus(15, 'browser'));
      // The resumed editor interval covers 9..15 only.
      expect(closed.last.applicationId, 'editor');
      expect(closed.last.activeSeconds, 360);
    });

    test('a pause expires on its own', () {
      recorder = build(
        policy: PrivacyPolicy(
          trackingEnabled: true,
          pausedUntil: wall(10),
        ),
      );
      recorder.handle(focus(0, 'editor'));
      expect(recorder.hasOpenInterval, isFalse);
      recorder.handle(focus(12, 'editor'));
      expect(recorder.hasOpenInterval, isTrue);
    });
  });

  group('daily aggregation', () {
    test('rolls up by local date × device × application', () {
      recorder.handle(focus(0, 'editor'));
      recorder.handle(focus(10, 'browser'));
      recorder.handle(focus(15, 'editor'));
      recorder.handle(focus(30, 'browser'));

      final byApp = aggregateDaily(
        closed,
        (startedAt) => PlainDate.of(startedAt),
      );
      expect(byApp, hasLength(2));
      final editor = byApp.singleWhere((d) => d.applicationId == 'editor');
      expect(editor.date, PlainDate.parse('2026-07-01'));
      expect(editor.activeSeconds, 600 + 900);
      expect(editor.intervalCount, 2);
      final browser =
          byApp.singleWhere((d) => d.applicationId == 'browser');
      expect(browser.activeSeconds, 300);
    });

    test('splits by local date when intervals cross days', () {
      final intervals = [
        UsageInterval(
          id: 'a',
          deviceId: 'laptop',
          platform: 'linux',
          applicationId: 'editor',
          applicationName: 'editor',
          startedAt: DateTime.utc(2026, 7, 1, 23),
          endedAt: DateTime.utc(2026, 7, 1, 23, 30),
          activeSeconds: 1800,
          source: 'test',
        ),
        UsageInterval(
          id: 'b',
          deviceId: 'laptop',
          platform: 'linux',
          applicationId: 'editor',
          applicationName: 'editor',
          startedAt: DateTime.utc(2026, 7, 2, 9),
          endedAt: DateTime.utc(2026, 7, 2, 10),
          activeSeconds: 3600,
          source: 'test',
        ),
      ];
      final daily =
          aggregateDaily(intervals, (startedAt) => PlainDate.of(startedAt));
      expect(daily.map((d) => d.date.toString()),
          ['2026-07-01', '2026-07-02']);
    });
  });
}
