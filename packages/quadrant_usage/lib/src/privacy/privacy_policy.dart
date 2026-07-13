/// What the recorder may collect right now. The default policy collects
/// nothing: tracking is off until the user enables it, and window titles
/// stay off even then unless separately opted into.
class PrivacyPolicy {
  const PrivacyPolicy({
    this.trackingEnabled = false,
    this.pausedUntil,
    this.privateMode = false,
    this.excludedApplicationIds = const {},
    this.collectWindowTitles = false,
  });

  /// Master switch; off by default.
  final bool trackingEnabled;

  /// Temporary pause ("15 minutes", "until tomorrow"); collection
  /// resumes automatically after this instant.
  final DateTime? pausedUntil;

  /// Explicit do-not-record mode until turned off.
  final bool privateMode;

  /// Applications that must never enter intervals or aggregates.
  final Set<String> excludedApplicationIds;

  /// Separate, explicit opt-in — titles often contain document names,
  /// search terms, or message content.
  final bool collectWindowTitles;

  bool isPaused(DateTime now) =>
      pausedUntil != null && now.isBefore(pausedUntil!);

  /// Whether an interval for [applicationId] may be open at [now].
  bool allowsRecording(String applicationId, DateTime now) =>
      trackingEnabled &&
      !privateMode &&
      !isPaused(now) &&
      !excludedApplicationIds.contains(applicationId);

  PrivacyPolicy copyWith({
    bool? trackingEnabled,
    DateTime? Function()? pausedUntil,
    bool? privateMode,
    Set<String>? excludedApplicationIds,
    bool? collectWindowTitles,
  }) =>
      PrivacyPolicy(
        trackingEnabled: trackingEnabled ?? this.trackingEnabled,
        pausedUntil:
            pausedUntil != null ? pausedUntil() : this.pausedUntil,
        privateMode: privateMode ?? this.privateMode,
        excludedApplicationIds:
            excludedApplicationIds ?? this.excludedApplicationIds,
        collectWindowTitles:
            collectWindowTitles ?? this.collectWindowTitles,
      );
}
