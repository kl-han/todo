import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_store/quadrant_store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../gateway/agent_scheduler.dart';
import '../gateway/desktop_notifier.dart';

/// The running agent: the local backend host plus the scheduler. Binds
/// only to loopback with the per-install bearer token; the GUI connects
/// like any remote client, which is exactly why closing it changes
/// nothing here.
class AgentHost {
  AgentHost({
    required this.databasePath,
    required this.token,
    this.port = 0,
    DesktopNotifier? notifier,
    this.tickInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : notifier = notifier ?? const NotifySendNotifier(),
        _clock = clock;

  final String databasePath;
  final String token;
  final int port;
  final DesktopNotifier notifier;
  final Duration tickInterval;
  final DateTime Function()? _clock;

  QuadrantDatabase? _database;
  HttpServer? _server;
  Timer? _timer;
  AgentScheduler? _scheduler;

  int get boundPort => _server!.port;

  AgentScheduler get scheduler => _scheduler!;

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
      clock: _clock,
    );
    _scheduler = AgentScheduler(services, notifier, clock: _clock);

    final api = buildApiHandler(
      ApiServerConfig(
        backendKind: BackendKind.standalone,
        authToken: token,
        schemaVersion: schemaVersion,
        vaults: (vaultId) => vaultId == 'default' ? services : null,
      ),
    );
    // Liveness for tooling and the tray UI; unauthenticated like /health.
    FutureOr<Response> handler(Request request) {
      if (request.method == 'GET' &&
          request.url.path == 'api/v1/agent/status') {
        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'component': 'quadrant-agent',
            'tick_interval_seconds': tickInterval.inSeconds,
            'last_tick_at': _scheduler?.lastTickAt?.toIso8601String(),
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      return api(request);
    }

    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4, // loopback only, never 0.0.0.0
      port,
    );
    _timer = Timer.periodic(tickInterval, (_) => _scheduler!.tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _server?.close(force: true);
    _database?.close();
  }
}
