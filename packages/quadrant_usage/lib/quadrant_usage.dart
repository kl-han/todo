/// Usage tracking for Quadrant Todo: the event-driven interval state
/// machine, the privacy policy that gates it, and daily aggregation.
///
/// Everything here is pure: collectors (Sway IPC, WinEvent) feed
/// [UsageEvent]s in; closed [UsageInterval]s come out. No polling, no
/// SQLite, no platform APIs — those live in the agent and the store.
library;

export 'src/aggregation/daily_aggregator.dart';
export 'src/events/usage_event.dart';
export 'src/intervals/usage_interval.dart';
export 'src/intervals/usage_recorder.dart';
export 'src/privacy/privacy_policy.dart';
