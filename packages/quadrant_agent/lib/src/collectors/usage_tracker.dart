import 'dart:convert';
import 'dart:io';

import 'package:quadrant_domain/quadrant_domain.dart' show PlainDate;
import 'package:quadrant_store/quadrant_store.dart';
import 'package:quadrant_usage/quadrant_usage.dart';

/// Persistent tracking settings (`agent-tracking.json`): the durable
/// part of the privacy policy. Pause and private mode are deliberately
/// runtime-only — a reboot clears them, tracking consent does not.
class TrackingConfig {
  const TrackingConfig({
    this.trackingEnabled = false,
    this.collectWindowTitles = false,
    this.excludedApplicationIds = const {},
    this.rawRetentionDays = 7,
  });

  factory TrackingConfig.fromJson(Map<String, Object?> json) =>
      TrackingConfig(
        trackingEnabled: json['tracking_enabled'] as bool? ?? false,
        collectWindowTitles:
            json['collect_window_titles'] as bool? ?? false,
        excludedApplicationIds: {
          ...(json['excluded_application_ids'] as List<Object?>? ?? [])
              .cast<String>(),
        },
        rawRetentionDays: json['raw_retention_days'] as int? ?? 7,
      );

  final bool trackingEnabled;
  final bool collectWindowTitles;
  final Set<String> excludedApplicationIds;

  /// 1, 7, 30, or 90 days of raw intervals; aggregates are unaffected.
  final int rawRetentionDays;

  Map<String, Object?> toJson() => {
        'tracking_enabled': trackingEnabled,
        'collect_window_titles': collectWindowTitles,
        'excluded_application_ids': excludedApplicationIds.toList()..sort(),
        'raw_retention_days': rawRetentionDays,
      };

  static TrackingConfig load(String path) {
    final file = File(path);
    if (!file.existsSync()) return const TrackingConfig();
    return TrackingConfig.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
    );
  }

  void save(String path) {
    Directory(File(path).parent.path).createSync(recursive: true);
    File(path).writeAsStringSync(jsonEncode(toJson()));
  }
}

/// Glue between the pure recorder and the usage store: closed intervals
/// are persisted and folded into their daily aggregate immediately (one
/// write per focus change, per the resource goals), and raw retention is
/// enforced on the agent's tick.
class UsageTracker {
  UsageTracker({
    required SqliteUsageRepository repository,
    required this.deviceId,
    required this.configPath,
    String platform = 'linux',
    String source = 'sway-ipc',
    DateTime Function()? clock,
  })  : _repository = repository,
        _clock = clock ?? (() => DateTime.now().toUtc()) {
    _config = TrackingConfig.load(configPath);
    recorder = UsageRecorder(
      deviceId: deviceId,
      platform: platform,
      source: source,
      policy: _policyFrom(_config),
      onIntervalClosed: (interval) {
        _repository.insertInterval(interval);
        _repository.mergeIntoDaily(interval, _localDateOf(interval.startedAt));
      },
    );
  }

  final SqliteUsageRepository _repository;
  final String deviceId;
  final String configPath;
  final DateTime Function() _clock;

  late final UsageRecorder recorder;
  late TrackingConfig _config;

  DateTime? _pausedUntil;
  bool _privateMode = false;

  TrackingConfig get config => _config;
  DateTime? get pausedUntil => _pausedUntil;
  bool get privateMode => _privateMode;

  /// The local calendar date of an instant, in the device's timezone.
  PlainDate _localDateOf(DateTime instant) => PlainDate.of(instant.toLocal());

  PrivacyPolicy _policyFrom(TrackingConfig config) => PrivacyPolicy(
        trackingEnabled: config.trackingEnabled,
        pausedUntil: _pausedUntil,
        privateMode: _privateMode,
        excludedApplicationIds: config.excludedApplicationIds,
        collectWindowTitles: config.collectWindowTitles,
      );

  void _apply() {
    final now = _clock();
    recorder.updatePolicy(
      _policyFrom(_config),
      at: now,
      monotonicMs: _monotonicNow(),
    );
  }

  // Policy changes are user actions, not high-frequency events; a fresh
  // stopwatch reading per change is fine.
  static final Stopwatch _monotonic = Stopwatch()..start();
  static int _monotonicNow() => _monotonic.elapsedMilliseconds;

  void setEnabled(bool enabled) {
    _config = TrackingConfig(
      trackingEnabled: enabled,
      collectWindowTitles: _config.collectWindowTitles,
      excludedApplicationIds: _config.excludedApplicationIds,
      rawRetentionDays: _config.rawRetentionDays,
    );
    if (enabled) {
      _pausedUntil = null;
      _privateMode = false;
    }
    _config.save(configPath);
    _apply();
  }

  void pauseFor(Duration duration) {
    _pausedUntil = _clock().add(duration);
    _apply();
  }

  void setPrivateMode(bool enabled) {
    _privateMode = enabled;
    _apply();
  }

  void setExclusions(Set<String> applicationIds) {
    _config = TrackingConfig(
      trackingEnabled: _config.trackingEnabled,
      collectWindowTitles: _config.collectWindowTitles,
      excludedApplicationIds: applicationIds,
      rawRetentionDays: _config.rawRetentionDays,
    );
    _config.save(configPath);
    _apply();
  }

  /// Called from the agent tick: drop raw intervals past retention.
  void enforceRetention() {
    _repository.pruneIntervalsBefore(
      _clock().subtract(Duration(days: _config.rawRetentionDays)),
    );
  }

  Map<String, Object?> statusJson() => {
        'tracking_enabled': _config.trackingEnabled,
        'paused_until': _pausedUntil?.toIso8601String(),
        'private_mode': _privateMode,
        'excluded_application_ids':
            _config.excludedApplicationIds.toList()..sort(),
        'collect_window_titles': _config.collectWindowTitles,
        'raw_retention_days': _config.rawRetentionDays,
      };
}
