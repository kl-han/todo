import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryFocusSessionRepository sessions;
  late FocusService service;
  var now = DateTime.utc(2026, 7, 1, 12);

  setUp(() {
    now = DateTime.utc(2026, 7, 1, 12);
    tasks = InMemoryTaskRepository();
    sessions = InMemoryFocusSessionRepository();
    service = FocusService(
      sessions,
      tasks,
      InMemoryRecurrenceRepository(tasks),
      clock: () => now,
    );
  });

  test('only one active session per vault', () {
    service.start(plannedFocusSeconds: 1500);
    expect(
      () => service.start(plannedFocusSeconds: 1500),
      throwsA(isA<StateConflictException>()),
    );
  });

  test('finishing frees the slot for the next session', () {
    final first = service.start(plannedFocusSeconds: 1500);
    service.finish(first.id, FocusResult.completed);
    expect(service.start(plannedFocusSeconds: 1500).phase,
        FocusPhase.running);
    expect(service.list(active: false), hasLength(1));
    expect(service.list(active: true), hasLength(1));
  });

  test('pause/resume/finish accumulate through the service clock', () {
    final session = service.start(plannedFocusSeconds: 1500);
    now = now.add(const Duration(minutes: 10));
    service.pause(session.id);
    now = now.add(const Duration(minutes: 2));
    service.resume(session.id);
    now = now.add(const Duration(minutes: 15));
    final finished = service.finish(session.id, FocusResult.completed);
    expect(finished.activeSeconds, 1500);
    expect(finished.pausedSeconds, 120);
    expect(finished.interruptionCount, 1);
  });

  test('invalid transitions surface as 409 conflicts', () {
    final session = service.start(plannedFocusSeconds: 1500);
    expect(
      () => service.resume(session.id),
      throwsA(isA<StateConflictException>()),
    );
  });

  test('dangling task references are 404s', () {
    expect(
      () => service.start(
        taskId: EntityId.generate(),
        plannedFocusSeconds: 1500,
      ),
      throwsA(isA<EntityNotFoundException>()),
    );
  });
}
