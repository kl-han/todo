import '../rules/validation.dart';

/// Where a session is in its lifecycle.
enum FocusPhase {
  running,
  paused,
  finished;

  String get wireName => name;

  static FocusPhase fromWire(String value) => switch (value) {
        'running' => running,
        'paused' => paused,
        'finished' => finished,
        _ => throw ArgumentError.value(value, 'value', 'unknown focus phase'),
      };
}

/// How a finished session ended.
enum FocusResult {
  completed,
  cancelled,
  interrupted;

  String get wireName => name;

  static FocusResult fromWire(String value) => switch (value) {
        'completed' => completed,
        'cancelled' => cancelled,
        'interrupted' => interrupted,
        _ => throw ArgumentError.value(value, 'value', 'unknown focus result'),
      };
}

const int minPlannedFocusSeconds = 60;
const int maxPlannedFocusSeconds = 14400; // four hours
const int maxPlannedBreakSeconds = 3600;

/// A Pomodoro focus session — a time record owned by the backend, not by
/// any GUI window, so closing the window never cancels the timer.
///
/// Durations accumulate only at phase transitions ([pause]/[resume]/
/// [finish]); the live portion of the current phase is derived by
/// clients. Negative wall-clock deltas are clamped to zero, so a clock
/// moving backward can never produce negative durations.
class FocusSession {
  FocusSession({
    required this.id,
    required this.plannedFocusSeconds,
    required this.startedAt,
    required this.lastTransitionAt,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.occurrenceId,
    this.deviceId,
    this.plannedBreakSeconds = 0,
    this.phase = FocusPhase.running,
    this.endedAt,
    this.activeSeconds = 0,
    this.pausedSeconds = 0,
    this.interruptionCount = 0,
    this.result,
    this.notes = '',
    this.version = 1,
  }) {
    if (taskId != null && occurrenceId != null) {
      throw DomainValidationError(
        'A focus session references at most one of task_id and '
        'occurrence_id.',
      );
    }
    if (plannedFocusSeconds < minPlannedFocusSeconds ||
        plannedFocusSeconds > maxPlannedFocusSeconds) {
      throw DomainValidationError(
        'planned_focus_seconds must be between $minPlannedFocusSeconds '
        'and $maxPlannedFocusSeconds.',
      );
    }
    if (plannedBreakSeconds < 0 ||
        plannedBreakSeconds > maxPlannedBreakSeconds) {
      throw DomainValidationError(
        'planned_break_seconds must be between 0 and '
        '$maxPlannedBreakSeconds.',
      );
    }
    if ((phase == FocusPhase.finished) != (endedAt != null)) {
      throw DomainValidationError(
        'ended_at is set exactly when the session is finished.',
      );
    }
    if ((phase == FocusPhase.finished) != (result != null)) {
      throw DomainValidationError(
        'result is set exactly when the session is finished.',
      );
    }
  }

  final String id;
  final String? taskId;
  final String? occurrenceId;
  final String? deviceId;
  final int plannedFocusSeconds;
  final int plannedBreakSeconds;
  final FocusPhase phase;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int activeSeconds;
  final int pausedSeconds;

  /// When the current phase began; the basis for live duration display
  /// and for the next accumulation.
  final DateTime lastTransitionAt;

  final int interruptionCount;
  final FocusResult? result;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isActive => phase != FocusPhase.finished;

  /// Seconds of the current phase as of [now]; clamped non-negative.
  int elapsedInPhase(DateTime now) {
    final delta = now.difference(lastTransitionAt).inSeconds;
    return delta < 0 ? 0 : delta;
  }

  FocusSession pause(DateTime now) {
    if (phase != FocusPhase.running) {
      throw StateError('Only a running session can pause.');
    }
    return _next(
      now,
      phase: FocusPhase.paused,
      activeSeconds: activeSeconds + elapsedInPhase(now),
      interruptionCount: interruptionCount + 1,
      lastTransitionAt: now,
    );
  }

  FocusSession resume(DateTime now) {
    if (phase != FocusPhase.paused) {
      throw StateError('Only a paused session can resume.');
    }
    return _next(
      now,
      phase: FocusPhase.running,
      pausedSeconds: pausedSeconds + elapsedInPhase(now),
      lastTransitionAt: now,
    );
  }

  FocusSession finish(DateTime now, FocusResult result, {String? notes}) {
    if (phase == FocusPhase.finished) {
      throw StateError('The session is already finished.');
    }
    return _next(
      now,
      phase: FocusPhase.finished,
      activeSeconds: phase == FocusPhase.running
          ? activeSeconds + elapsedInPhase(now)
          : activeSeconds,
      pausedSeconds: phase == FocusPhase.paused
          ? pausedSeconds + elapsedInPhase(now)
          : pausedSeconds,
      endedAt: now,
      result: result,
      notes: notes == null ? null : validateTaskNotes(notes),
      lastTransitionAt: now,
    );
  }

  FocusSession _next(
    DateTime now, {
    FocusPhase? phase,
    DateTime? endedAt,
    int? activeSeconds,
    int? pausedSeconds,
    DateTime? lastTransitionAt,
    int? interruptionCount,
    FocusResult? result,
    String? notes,
  }) =>
      FocusSession(
        id: id,
        taskId: taskId,
        occurrenceId: occurrenceId,
        deviceId: deviceId,
        plannedFocusSeconds: plannedFocusSeconds,
        plannedBreakSeconds: plannedBreakSeconds,
        phase: phase ?? this.phase,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        activeSeconds: activeSeconds ?? this.activeSeconds,
        pausedSeconds: pausedSeconds ?? this.pausedSeconds,
        lastTransitionAt: lastTransitionAt ?? this.lastTransitionAt,
        interruptionCount: interruptionCount ?? this.interruptionCount,
        result: result ?? this.result,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: now,
        version: version + 1,
      );
}
