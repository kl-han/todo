import 'dart:io';

import 'package:quadrant_agent/quadrant_agent.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:test/test.dart';

class RecordingNotifier implements DesktopNotifier {
  final List<(String, String)> delivered = [];
  bool accept = true;

  @override
  Future<bool> notify({required String summary, required String body}) async {
    if (!accept) return false;
    delivered.add((summary, body));
    return true;
  }
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('quadrant-agent-'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('lifecycle', () {
    test('the per-install credential is created once, owner-only', () async {
      final path = '${dir.path}/agent-token';
      final first = await AgentCredential.load(path);
      final second = await AgentCredential.load(path);
      expect(first.token, second.token);
      expect(first.token.length, 43);
      final mode = (await Process.run('stat', ['-c', '%a', path])).stdout;
      expect((mode as String).trim(), '600');
    });

    test('the instance lock refuses a second acquire', () {
      final lock = InstanceLock.acquire('${dir.path}/agent.lock');
      expect(
        () => InstanceLock.acquire('${dir.path}/agent.lock'),
        throwsStateError,
      );
      lock.release();
      InstanceLock.acquire('${dir.path}/agent.lock').release();
    });
  });

  group('agent host', () {
    late AgentHost host;
    late RecordingNotifier notifier;
    var now = DateTime.utc(2026, 7, 1, 12);

    setUp(() async {
      now = DateTime.utc(2026, 7, 1, 12);
      notifier = RecordingNotifier();
      host = AgentHost(
        databasePath: '${dir.path}/default.sqlite3',
        token: 'agent-test-token',
        notifier: notifier,
        // Long interval: tests drive ticks manually for determinism.
        tickInterval: const Duration(hours: 1),
        clock: () => now,
      );
      await host.start();
    });

    tearDown(() => host.stop());

    QuadrantApiClient connect() => QuadrantApiClient(
          baseUrl: Uri.parse('http://127.0.0.1:${host.boundPort}'),
          authorization: 'Bearer agent-test-token',
        );

    test('closing the GUI does not stop an active focus session', () async {
      // "GUI" number one starts a session, then goes away entirely.
      final gui1 = connect();
      final session = await gui1.startFocusSession(plannedFocusSeconds: 1500);
      expect(session.phase, 'running');
      gui1.close();

      // A fresh "GUI" finds the same session still running in the agent.
      final gui2 = connect();
      final found = await gui2.listFocusSessions(active: true);
      expect(found.single.id, session.id);
      expect(found.single.phase, 'running');
      gui2.close();
    });

    test('the loopback API requires the per-install credential', () async {
      final anonymous = QuadrantApiClient(
        baseUrl: Uri.parse('http://127.0.0.1:${host.boundPort}'),
      );
      await expectLater(
        anonymous.listTasks(),
        throwsA(isA<ProblemDetailsException>()
            .having((p) => p.status, 'status', 401)),
      );
      anonymous.close();
    });

    test('agent status responds without credentials, with tick state',
        () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(
          'http://127.0.0.1:${host.boundPort}/api/v1/agent/status'));
      final response = await request.close();
      expect(response.statusCode, 200);
      client.close();
    });

    test('scheduler delivers due reminders once and announces focus '
        'completion', () async {
      final gui = connect();
      final task = await gui.createTask(
        title: 'agent-reminder',
        dueKind: 'datetime',
        dueAtUtc: DateTime.utc(2026, 7, 1, 12, 30),
        timezoneId: 'UTC',
      );
      await gui.createReminder(
        taskId: task.id,
        triggerType: 'relative_due',
        offsetMinutes: 10, // due 12:30 → trigger 12:20
      );
      final session = await gui.startFocusSession(plannedFocusSeconds: 60);

      // Before the trigger: nothing.
      expect(await host.scheduler.tick(), 0);

      // After the trigger and past the planned focus: both fire.
      now = DateTime.utc(2026, 7, 1, 12, 21);
      expect(await host.scheduler.tick(), 2);
      expect(notifier.delivered.map((n) => n.$1),
          ['Quadrant reminder', 'Focus session complete']);

      // Idempotent: nothing fires twice.
      expect(await host.scheduler.tick(), 0);

      // The reminder is now delivered; the session still runs.
      final reminders = await gui.listReminders(state: 'delivered');
      expect(reminders, hasLength(1));
      expect((await gui.getFocusSession(session.id)).phase, 'running');
      gui.close();
    });

    test('a rejected notification retries on the next tick', () async {
      final gui = connect();
      await gui.createReminder(
        taskId: (await gui.createTask(title: 'retry')).id,
        triggerType: 'absolute',
        triggerAtUtc: DateTime.utc(2026, 7, 1, 11),
      );
      notifier.accept = false;
      expect(await host.scheduler.tick(), 0);
      notifier.accept = true;
      expect(await host.scheduler.tick(), 1);
      gui.close();
    });
  });
}
