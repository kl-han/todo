/// Wire representation of a focus session.
class FocusSessionDto {
  const FocusSessionDto({
    required this.id,
    required this.plannedFocusSeconds,
    required this.plannedBreakSeconds,
    required this.phase,
    required this.startedAt,
    required this.activeSeconds,
    required this.pausedSeconds,
    required this.lastTransitionAt,
    required this.interruptionCount,
    required this.notes,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.occurrenceId,
    this.deviceId,
    this.endedAt,
    this.result,
  });

  factory FocusSessionDto.fromJson(Map<String, Object?> json) =>
      FocusSessionDto(
        id: json['id'] as String,
        plannedFocusSeconds: json['planned_focus_seconds'] as int,
        plannedBreakSeconds: json['planned_break_seconds'] as int,
        phase: json['phase'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        activeSeconds: json['active_seconds'] as int,
        pausedSeconds: json['paused_seconds'] as int,
        lastTransitionAt:
            DateTime.parse(json['last_transition_at'] as String),
        interruptionCount: json['interruption_count'] as int,
        notes: json['notes'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        taskId: json['task_id'] as String?,
        occurrenceId: json['occurrence_id'] as String?,
        deviceId: json['device_id'] as String?,
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.parse(json['ended_at'] as String),
        result: json['result'] as String?,
      );

  final String id;
  final String? taskId;
  final String? occurrenceId;
  final String? deviceId;
  final int plannedFocusSeconds;
  final int plannedBreakSeconds;

  /// `running`, `paused`, or `finished`.
  final String phase;

  final DateTime startedAt;
  final DateTime? endedAt;

  /// Accumulated at phase transitions only; compute the live display
  /// from [phase], [lastTransitionAt], and a local clock.
  final int activeSeconds;

  final int pausedSeconds;
  final DateTime lastTransitionAt;
  final int interruptionCount;

  /// `completed`, `cancelled`, or `interrupted`; null while unfinished.
  final String? result;

  final String notes;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => phase != 'finished';
}
