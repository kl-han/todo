/// One closed span of foreground use of one application. Durations come
/// from the monotonic clock; the wall timestamps are for calendar
/// reporting only and never enter duration arithmetic.
class UsageInterval {
  const UsageInterval({
    required this.id,
    required this.deviceId,
    required this.platform,
    required this.applicationId,
    required this.applicationName,
    required this.startedAt,
    required this.endedAt,
    required this.activeSeconds,
    required this.source,
    this.categoryId,
    this.idleSeconds = 0,
    this.confidence = 'exact',
    this.windowTitle,
  });

  final String id;
  final String deviceId;

  /// `linux`, `windows`, `android`.
  final String platform;

  final String applicationId;
  final String applicationName;
  final String? categoryId;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Monotonic duration of the interval.
  final int activeSeconds;

  final int idleSeconds;

  /// Which collector produced this (`sway-ipc`, `winevent`, …).
  final String source;

  final String confidence;

  /// Null unless title collection is explicitly enabled.
  final String? windowTitle;
}
