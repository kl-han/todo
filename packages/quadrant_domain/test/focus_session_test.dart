import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 7, 1, 12);

FocusSession _session({int planned = 1500}) => FocusSession(
      id: EntityId.generate(),
      plannedFocusSeconds: planned,
      startedAt: t0,
      lastTransitionAt: t0,
      createdAt: t0,
      updatedAt: t0,
    );

void main() {
  group('FocusSession transitions', () {
    test('pause accumulates active time and counts the interruption', () {
      final paused = _session().pause(t0.add(const Duration(minutes: 10)));
      expect(paused.phase, FocusPhase.paused);
      expect(paused.activeSeconds, 600);
      expect(paused.pausedSeconds, 0);
      expect(paused.interruptionCount, 1);
      expect(paused.version, 2);
    });

    test('resume accumulates paused time', () {
      final resumed = _session()
          .pause(t0.add(const Duration(minutes: 10)))
          .resume(t0.add(const Duration(minutes: 12)));
      expect(resumed.phase, FocusPhase.running);
      expect(resumed.activeSeconds, 600);
      expect(resumed.pausedSeconds, 120);
    });

    test('finish closes the current phase into the totals', () {
      final finished = _session()
          .pause(t0.add(const Duration(minutes: 10)))
          .resume(t0.add(const Duration(minutes: 12)))
          .finish(t0.add(const Duration(minutes: 27)), FocusResult.completed,
              notes: 'solid block');
      expect(finished.phase, FocusPhase.finished);
      expect(finished.activeSeconds, 600 + 900);
      expect(finished.pausedSeconds, 120);
      expect(finished.result, FocusResult.completed);
      expect(finished.endedAt, t0.add(const Duration(minutes: 27)));
      expect(finished.notes, 'solid block');
    });

    test('a clock moving backward never produces negative durations', () {
      final paused =
          _session().pause(t0.subtract(const Duration(minutes: 5)));
      expect(paused.activeSeconds, 0);
    });

    test('invalid transitions throw StateError', () {
      final session = _session();
      expect(() => session.resume(t0), throwsStateError);
      final paused = session.pause(t0);
      expect(() => paused.pause(t0), throwsStateError);
      final finished = paused.finish(t0, FocusResult.cancelled);
      expect(() => finished.pause(t0), throwsStateError);
      expect(
          () => finished.finish(t0, FocusResult.completed), throwsStateError);
    });

    test('construction invariants', () {
      expect(() => _session(planned: 30),
          throwsA(isA<DomainValidationError>()));
      expect(
        () => FocusSession(
          id: 'x',
          taskId: 'a',
          occurrenceId: 'b',
          plannedFocusSeconds: 1500,
          startedAt: t0,
          lastTransitionAt: t0,
          createdAt: t0,
          updatedAt: t0,
        ),
        throwsA(isA<DomainValidationError>()),
      );
    });
  });
}
