import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:quadrant_agent/quadrant_agent.dart';
import 'package:quadrant_usage/quadrant_usage.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late AgentHost host;
  final now = DateTime.utc(2026, 7, 1, 12);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('agent-usage-');
    host = AgentHost(
      databasePath: '${dir.path}/default.sqlite3',
      usageDatabasePath: '${dir.path}/usage.sqlite3',
      trackingConfigPath: '${dir.path}/agent-tracking.json',
      deviceId: 'laptop',
      token: 'usage-test-token',
      notifier: const LogNotifier(),
      tickInterval: const Duration(hours: 1),
      clock: () => now,
    );
    await host.start();
  });

  tearDown(() async {
    await host.stop();
    dir.deleteSync(recursive: true);
  });

  Uri url(String path) =>
      Uri.parse('http://127.0.0.1:${host.boundPort}$path');

  Map<String, String> auth() => {
        'authorization': 'Bearer usage-test-token',
        'content-type': 'application/json',
      };

  Future<Map<String, Object?>> getJson(String path) async {
    final response = await http.get(url(path), headers: auth());
    expect(response.statusCode, 200, reason: path);
    return jsonDecode(response.body) as Map<String, Object?>;
  }

  void feedInterval({String app = 'editor', int minutes = 10}) {
    final recorder = host.tracker!.recorder;
    recorder.handle(FocusChanged(
      at: now,
      monotonicMs: 0,
      applicationId: app,
      applicationName: app,
    ));
    recorder.handle(FocusChanged(
      at: now.add(Duration(minutes: minutes)),
      monotonicMs: minutes * 60000,
      applicationId: 'other',
      applicationName: 'other',
    ));
  }

  test('tracking is off by default and status says so openly', () async {
    final status = jsonDecode(
      (await http.get(url('/api/v1/agent/status'))).body,
    ) as Map<String, Object?>;
    final tracking = status['tracking'] as Map<String, Object?>;
    expect(tracking['tracking_enabled'], false);
    expect(tracking['collect_window_titles'], false);
  });

  test('agent usage routes require the credential', () async {
    final response = await http.get(url('/api/v1/agent/tracking'));
    expect(response.statusCode, 401);
  });

  test('start → record → intervals and daily → delete-all round trip',
      () async {
    await http.post(url('/api/v1/agent/tracking/start'), headers: auth());
    expect((await getJson('/api/v1/agent/tracking'))['tracking_enabled'],
        true);

    feedInterval();

    final intervals = await getJson(
        '/api/v1/agent/usage/intervals?from=2026-07-01T00:00:00Z'
        '&to=2026-07-02T00:00:00Z');
    final list = (intervals['intervals'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(list.single['application_id'], 'editor');
    expect(list.single['active_seconds'], 600);
    expect(list.single['window_title'], isNull);

    final daily = await getJson(
        '/api/v1/agent/usage/daily?from=2026-07-01&to=2026-07-01');
    final days =
        (daily['daily'] as List<Object?>).cast<Map<String, Object?>>();
    expect(days.single['application_id'], 'editor');
    expect(days.single['active_seconds'], 600);

    final deleted =
        await http.delete(url('/api/v1/agent/usage'), headers: auth());
    expect(deleted.statusCode, 204);
    final after = await getJson(
        '/api/v1/agent/usage/daily?from=2026-07-01&to=2026-07-01');
    expect(after['daily'], isEmpty);
  });

  test('private mode and exclusions gate recording through the API',
      () async {
    await http.post(url('/api/v1/agent/tracking/start'), headers: auth());
    await http.post(
      url('/api/v1/agent/tracking/private'),
      headers: auth(),
      body: jsonEncode({'enabled': true}),
    );
    feedInterval();
    var daily = await getJson(
        '/api/v1/agent/usage/daily?from=2026-07-01&to=2026-07-01');
    expect(daily['daily'], isEmpty, reason: 'private mode records nothing');

    await http.post(
      url('/api/v1/agent/tracking/private'),
      headers: auth(),
      body: jsonEncode({'enabled': false}),
    );
    await http.put(
      url('/api/v1/agent/tracking/exclusions'),
      headers: auth(),
      body: jsonEncode({
        'application_ids': ['editor'],
      }),
    );
    feedInterval();
    daily = await getJson(
        '/api/v1/agent/usage/daily?from=2026-07-01&to=2026-07-01');
    expect(daily['daily'], isEmpty,
        reason: 'an excluded application never enters aggregates');
  });

  test('tracking consent persists across agent restarts; pause does not',
      () async {
    await http.post(url('/api/v1/agent/tracking/start'), headers: auth());
    await http.post(
      url('/api/v1/agent/tracking/pause'),
      headers: auth(),
      body: jsonEncode({'minutes': 15}),
    );
    var status = await getJson('/api/v1/agent/tracking');
    expect(status['paused_until'], isNotNull);

    await host.stop();
    host = AgentHost(
      databasePath: '${dir.path}/default.sqlite3',
      usageDatabasePath: '${dir.path}/usage.sqlite3',
      trackingConfigPath: '${dir.path}/agent-tracking.json',
      deviceId: 'laptop',
      token: 'usage-test-token',
      notifier: const LogNotifier(),
      tickInterval: const Duration(hours: 1),
      clock: () => now,
    );
    await host.start();

    status = await getJson('/api/v1/agent/tracking');
    expect(status['tracking_enabled'], true, reason: 'consent is durable');
    expect(status['paused_until'], isNull, reason: 'pause is runtime-only');
  });
}
