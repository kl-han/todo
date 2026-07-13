import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart' show PlainDate;
import 'package:quadrant_store/quadrant_store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../collectors/sway_collector.dart';
import '../collectors/usage_tracker.dart';
import '../gateway/agent_scheduler.dart';
import '../gateway/desktop_notifier.dart';

/// The running agent: the local backend host plus the scheduler and the
/// usage tracker. Binds only to loopback with the per-install bearer
/// token; the GUI connects like a remote client, which is exactly why
/// closing it changes nothing here.
class AgentHost {
  AgentHost({
    required this.databasePath,
    required this.token,
    this.usageDatabasePath,
    this.trackingConfigPath,
    this.deviceId = 'desktop',
    this.port = 0,
    DesktopNotifier? notifier,
    this.tickInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : notifier = notifier ?? const NotifySendNotifier(),
        _clock = clock;

  final String databasePath;
  final String? usageDatabasePath;
  final String? trackingConfigPath;
  final String deviceId;
  final String token;
  final int port;
  final DesktopNotifier notifier;
  final Duration tickInterval;
  final DateTime Function()? _clock;

  QuadrantDatabase? _database;
  UsageDatabase? _usageDatabase;
  SqliteUsageRepository? _usageRepository;
  UsageTracker? _tracker;
  SwayCollector? _swayCollector;
  HttpServer? _server;
  Timer? _timer;
  AgentScheduler? _scheduler;

  int get boundPort => _server!.port;

  AgentScheduler get scheduler => _scheduler!;

  /// Non-null when usage tracking storage is configured.
  UsageTracker? get tracker => _tracker;

  Future<void> start({void Function(String movedTo)? onCorruptMovedAside}) async {
    // Same recovery posture as the embedded backend: the agent must
    // always boot; a damaged vault is moved aside for triage.
    final database = QuadrantDatabase.openWithRecovery(
      databasePath,
      onCorruptMovedAside: onCorruptMovedAside,
    );
    _database = database;
    final services = AppServices(
      taskRepository: SqliteTaskRepository(database),
      tagRepository: SqliteTagRepository(database),
      recurrenceRepository: SqliteRecurrenceRepository(database),
      reminderRepository: SqliteReminderRepository(database),
      focusSessionRepository: SqliteFocusSessionRepository(database),
      planningRepository: SqlitePlanningRepository(database),
      reportRepository: SqliteReportRepository(database),
      clock: _clock,
    );
    _scheduler = AgentScheduler(services, notifier, clock: _clock);

    if (usageDatabasePath != null) {
      _usageDatabase = UsageDatabase.open(usageDatabasePath!);
      _usageRepository = SqliteUsageRepository(_usageDatabase!);
      _tracker = UsageTracker(
        repository: _usageRepository!,
        deviceId: deviceId,
        configPath: trackingConfigPath ??
            '${File(usageDatabasePath!).parent.path}/agent-tracking.json',
        clock: _clock,
      );
      // The collector attaches only where a compositor is reachable and
      // tracking was enabled by the user ("disabling tracking prevents
      // collector startup").
      final swaySock = Platform.environment['SWAYSOCK'];
      if (swaySock != null && _tracker!.config.trackingEnabled) {
        _swayCollector = SwayCollector(
          socketPath: swaySock,
          onEvent: _tracker!.recorder.handle,
        );
        await _swayCollector!.start();
      }
    }

    final api = buildApiHandler(
      ApiServerConfig(
        backendKind: BackendKind.standalone,
        authToken: token,
        schemaVersion: schemaVersion,
        vaults: (vaultId) => vaultId == 'default' ? services : null,
      ),
    );
    FutureOr<Response> handler(Request request) {
      final segments = request.url.pathSegments;
      final isAgentRoute = segments.length >= 3 &&
          segments[0] == 'api' &&
          segments[1] == 'v1' &&
          segments[2] == 'agent';
      if (isAgentRoute) return _agentRoute(request);
      return api(request);
    }

    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4, // loopback only, never 0.0.0.0
      port,
    );
    _timer = Timer.periodic(tickInterval, (_) async {
      await _scheduler!.tick();
      _tracker?.enforceRetention();
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _swayCollector?.stop();
    await _server?.close(force: true);
    _database?.close();
    _usageDatabase?.close();
  }

  // ---- Agent-scoped routes (loopback only; documented as agent-only
  // in the API docs — backends never serve these) ----

  Future<Response> _agentRoute(Request request) async {
    final path = request.url.pathSegments.skip(2).join('/');
    if (request.method == 'GET' && path == 'agent/status') {
      return _json(200, {
        'status': 'ok',
        'component': 'quadrant-agent',
        'tick_interval_seconds': tickInterval.inSeconds,
        'last_tick_at': _scheduler?.lastTickAt?.toIso8601String(),
        'tracking': _tracker?.statusJson(),
      });
    }
    if (request.headers['authorization'] != 'Bearer $token') {
      return _problem(401, 'problems/unauthenticated', 'Unauthenticated',
          'Agent routes require the per-install token.');
    }
    final tracker = _tracker;
    if (tracker == null) {
      return _problem(404, 'problems/not-found', 'Not Found',
          'Usage tracking storage is not configured.');
    }

    switch ((request.method, path)) {
      case ('GET', 'agent/tracking'):
        return _json(200, tracker.statusJson());
      case ('POST', 'agent/tracking/start'):
        tracker.setEnabled(true);
        return _json(200, tracker.statusJson());
      case ('POST', 'agent/tracking/stop'):
        tracker.setEnabled(false);
        return _json(200, tracker.statusJson());
      case ('POST', 'agent/tracking/pause'):
        final body = await _body(request);
        final minutes = body['minutes'] as int?;
        if (minutes == null || minutes < 1) {
          return _problem(400, 'problems/validation', 'Invalid Request',
              'Field "minutes" (>= 1) is required.');
        }
        tracker.pauseFor(Duration(minutes: minutes));
        return _json(200, tracker.statusJson());
      case ('POST', 'agent/tracking/private'):
        final body = await _body(request);
        final enabled = body['enabled'] as bool?;
        if (enabled == null) {
          return _problem(400, 'problems/validation', 'Invalid Request',
              'Field "enabled" is required.');
        }
        tracker.setPrivateMode(enabled);
        return _json(200, tracker.statusJson());
      case ('PUT', 'agent/tracking/exclusions'):
        final body = await _body(request);
        final ids = (body['application_ids'] as List<Object?>?)
            ?.cast<String>();
        if (ids == null) {
          return _problem(400, 'problems/validation', 'Invalid Request',
              'Field "application_ids" is required.');
        }
        tracker.setExclusions(ids.toSet());
        return _json(200, tracker.statusJson());
      case ('GET', 'agent/usage/intervals'):
        final range = _instantRange(request);
        if (range == null) {
          return _problem(400, 'problems/validation', 'Invalid Request',
              'Query parameters "from" and "to" (RFC 3339) are required.');
        }
        final intervals =
            _usageRepository!.intervalsBetween(range.$1, range.$2);
        return _json(200, {
          'intervals': [
            for (final interval in intervals)
              {
                'id': interval.id,
                'device_id': interval.deviceId,
                'platform': interval.platform,
                'application_id': interval.applicationId,
                'application_name': interval.applicationName,
                'category_id': interval.categoryId,
                'started_at': interval.startedAt.toIso8601String(),
                'ended_at': interval.endedAt.toIso8601String(),
                'active_seconds': interval.activeSeconds,
                'idle_seconds': interval.idleSeconds,
                'source': interval.source,
                'confidence': interval.confidence,
                'window_title': interval.windowTitle,
              },
          ],
        });
      case ('GET', 'agent/usage/daily'):
        final params = request.url.queryParameters;
        final PlainDate from;
        final PlainDate to;
        try {
          from = PlainDate.parse(params['from'] ?? '');
          to = PlainDate.parse(params['to'] ?? '');
        } on Object {
          return _problem(400, 'problems/validation', 'Invalid Request',
              'Query parameters "from" and "to" (YYYY-MM-DD) are required.');
        }
        final days = _usageRepository!.dailyBetween(from, to);
        return _json(200, {
          'daily': [
            for (final day in days)
              {
                'date': day.date.toString(),
                'device_id': day.deviceId,
                'application_id': day.applicationId,
                'category_id': day.categoryId,
                'active_seconds': day.activeSeconds,
                'idle_seconds': day.idleSeconds,
                'focus_session_seconds': day.focusSessionSeconds,
                'interval_count': day.intervalCount,
              },
          ],
        });
      case ('DELETE', 'agent/usage'):
        _usageRepository!.deleteAll();
        return Response(204);
      default:
        return _problem(
            404, 'problems/not-found', 'Not Found', 'No such agent route.');
    }
  }

  static Future<Map<String, Object?>> _body(Request request) async {
    final text = await request.readAsString();
    if (text.isEmpty) return const {};
    final decoded = jsonDecode(text);
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  (DateTime, DateTime)? _instantRange(Request request) {
    final from = DateTime.tryParse(request.url.queryParameters['from'] ?? '');
    final to = DateTime.tryParse(request.url.queryParameters['to'] ?? '');
    if (from == null || to == null) return null;
    return (from.toUtc(), to.toUtc());
  }

  static Response _json(int status, Map<String, Object?> body) => Response(
        status,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
      );

  static Response _problem(
          int status, String type, String title, String detail) =>
      Response(
        status,
        body: jsonEncode({
          'type': type,
          'title': title,
          'status': status,
          'detail': detail,
        }),
        headers: {'content-type': 'application/problem+json'},
      );
}
