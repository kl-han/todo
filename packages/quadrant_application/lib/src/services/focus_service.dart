import 'package:quadrant_domain/quadrant_domain.dart';

import '../errors.dart';
import '../repositories.dart';

/// Focus-session commands and queries. The backend — on desktop, the
/// quadrant-agent — owns the timer state; a GUI is just a viewer, so
/// closing the window never cancels a session.
class FocusService {
  FocusService(this._sessions, this._tasks, this._recurrence,
      {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());

  final FocusSessionRepository _sessions;
  final TaskRepository _tasks;
  final RecurrenceRepository _recurrence;
  final DateTime Function() _clock;

  /// Starts a session. At most one unfinished session exists per vault.
  FocusSession start({
    String? taskId,
    String? occurrenceId,
    String? deviceId,
    required int plannedFocusSeconds,
    int plannedBreakSeconds = 0,
    String notes = '',
  }) {
    final active = _sessions.findActive();
    if (active != null) {
      throw StateConflictException(
        'Focus session ${active.id} is already active.',
      );
    }
    if (taskId != null) {
      final task = _tasks.findById(taskId);
      if (task == null || task.isDeleted) {
        throw EntityNotFoundException('No task $taskId.');
      }
    }
    if (occurrenceId != null &&
        _recurrence.findOccurrenceById(occurrenceId) == null) {
      throw EntityNotFoundException('No occurrence $occurrenceId.');
    }

    final now = _clock();
    final session = FocusSession(
      id: EntityId.generate(),
      taskId: taskId,
      occurrenceId: occurrenceId,
      deviceId: deviceId,
      plannedFocusSeconds: plannedFocusSeconds,
      plannedBreakSeconds: plannedBreakSeconds,
      notes: validateTaskNotes(notes),
      startedAt: now,
      lastTransitionAt: now,
      createdAt: now,
      updatedAt: now,
    );
    _sessions.insert(session);
    return session;
  }

  FocusSession get(String id) {
    final session = _sessions.findById(id);
    if (session == null) {
      throw EntityNotFoundException('No focus session $id.');
    }
    return session;
  }

  List<FocusSession> list({bool? active, String? taskId}) =>
      _sessions.list(active: active, taskId: taskId);

  FocusSession pause(String id, {int? expectedVersion}) =>
      _transition(id, expectedVersion, (session, now) => session.pause(now));

  FocusSession resume(String id, {int? expectedVersion}) =>
      _transition(id, expectedVersion, (session, now) => session.resume(now));

  FocusSession finish(
    String id,
    FocusResult result, {
    String? notes,
    int? expectedVersion,
  }) =>
      _transition(id, expectedVersion,
          (session, now) => session.finish(now, result, notes: notes));

  FocusSession _transition(
    String id,
    int? expectedVersion,
    FocusSession Function(FocusSession, DateTime) apply,
  ) {
    final session = get(id);
    if (expectedVersion != null && expectedVersion != session.version) {
      throw VersionConflictException(currentVersion: session.version);
    }
    final FocusSession next;
    try {
      next = apply(session, _clock());
    } on StateError catch (error) {
      throw StateConflictException(error.message);
    }
    _sessions.update(next);
    return next;
  }
}
