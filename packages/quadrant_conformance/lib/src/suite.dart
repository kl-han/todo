import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:test/test.dart';

import 'harness.dart';

/// The backend contract, written once and executed against every harness.
///
/// Everything asserted here is normative API behavior from
/// `api/openapi.yaml`; anything backend-specific is limited to the
/// `backend` field of the health report. Tests share one live backend, so
/// each test works only with entities it created itself.
void runBackendContractSuite(
  Future<BackendHarness> Function() startHarness,
) {
  late BackendHarness harness;
  late QuadrantApiClient client;

  setUpAll(() async {
    harness = await startHarness();
    client = QuadrantApiClient(
      baseUrl: harness.baseUrl,
      authorization: harness.authorization,
    );
    await client.waitUntilHealthy(timeout: const Duration(seconds: 10));
  });

  tearDownAll(() async {
    client.close();
    await harness.stop();
  });

  group('system contract', () {
    test('GET /api/v1/health reports readiness without credentials',
        () async {
      final anonymous = QuadrantApiClient(baseUrl: harness.baseUrl);
      final report = await anonymous.health();
      expect(report.isReady, isTrue);
      expect(report.apiVersion, 'v1');
      expect(report.schemaVersion, greaterThanOrEqualTo(1));
      expect(report.backend, harness.expectedBackendKind);
      anonymous.close();
    });

    test('data routes reject missing credentials with a 401 problem',
        () async {
      final response = await http.get(
        harness.baseUrl.resolve('/api/v1/vaults/default/tasks'),
      );
      expect(response.statusCode, 401);
      expect(
        response.headers['content-type'],
        contains('application/problem+json'),
      );
    });

    test('unknown routes return a 404 problem, not a bare 404', () async {
      final response = await http.get(
        harness.baseUrl.resolve('/api/v1/definitely-not-a-route'),
        headers: {'authorization': harness.authorization},
      );
      expect(response.statusCode, 404);
      expect(
        response.headers['content-type'],
        contains('application/problem+json'),
      );
    });

    test('GET /api/v1/capabilities negotiates version and features',
        () async {
      final capabilities = await client.capabilities();
      expect(capabilities.supportsV1, isTrue);
      expect(capabilities.schemaVersion, greaterThanOrEqualTo(1));
      expect(
        capabilities.features,
        containsAll(['tasks', 'tags', 'quadrants', 'etag-concurrency']),
      );
    });

    test('GET /api/v1/vaults lists the default vault', () async {
      final vaults = await client.listVaults();
      expect(vaults, contains('default'));
    });

    test('unknown vaults are a 404 problem', () async {
      await expectLater(
        client.listTasks(vault: 'no-such-vault'),
        throwsA(_problem(404, 'problems/not-found')),
      );
    });
  });

  group('task contract', () {
    test('create → read round-trip with derived quadrant and ETag version',
        () async {
      final created = await client.createTask(
        title: '  round trip  ',
        notes: 'notes',
        isUrgent: true,
        isImportant: true,
      );
      expect(created.title, 'round trip', reason: 'title is trimmed');
      expect(created.quadrant, 1);
      expect(created.status, 'open');
      expect(created.version, 1);

      final fetched = await client.getTask(created.id);
      expect(fetched.notes, 'notes');
      expect(fetched.quadrant, 1);
    });

    test('completion toggle: open → completed → open', () async {
      final task = await client.createTask(title: 'toggle');

      final completed = await client.updateTask(
        task.id,
        status: 'completed',
        ifMatchVersion: task.version,
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
      expect(completed.version, task.version + 1);

      final reopened = await client.updateTask(
        completed.id,
        status: 'open',
        ifMatchVersion: completed.version,
      );
      expect(reopened.isCompleted, isFalse);
      expect(reopened.completedAt, isNull);
      expect(reopened.version, completed.version + 1);
    });

    test('stale If-Match yields 412 with the current version', () async {
      final task = await client.createTask(title: 'conflict');
      await client.updateTask(task.id, title: 'first writer');

      await expectLater(
        client.updateTask(
          task.id,
          title: 'second writer',
          ifMatchVersion: task.version,
        ),
        throwsA(_problem(412, 'problems/version-conflict')),
      );
    });

    test('classification edits move tasks between quadrants', () async {
      final task = await client.createTask(title: 'reclassify');
      expect(task.quadrant, 4);
      final moved = await client.updateTask(
        task.id,
        isUrgent: true,
        isImportant: true,
      );
      expect(moved.quadrant, 1);
    });

    test('soft delete hides, restore brings back', () async {
      final task = await client.createTask(title: 'delete me');
      await client.deleteTask(task.id, ifMatchVersion: task.version);

      await expectLater(
        client.getTask(task.id),
        throwsA(_problem(404, 'problems/not-found')),
      );

      final restored = await client.restoreTask(task.id);
      expect(restored.deletedAt, isNull);
      final fetched = await client.getTask(task.id);
      expect(fetched.title, 'delete me');
    });

    test('stale If-Match on DELETE is a 412, and the task survives',
        () async {
      final task = await client.createTask(title: 'delete conflict');
      await client.updateTask(task.id, notes: 'moved on');

      await expectLater(
        client.deleteTask(task.id, ifMatchVersion: task.version),
        throwsA(_problem(412, 'problems/version-conflict')),
      );
      final alive = await client.getTask(task.id);
      expect(alive.deletedAt, isNull);
    });

    test('unknown request fields are ignored, not rejected (additive '
        'compatibility)', () async {
      final response = await http.post(
        harness.baseUrl.resolve('/api/v1/vaults/default/tasks'),
        headers: {
          'authorization': harness.authorization,
          'content-type': 'application/json',
        },
        body: '{"title":"tolerant","some_future_field":123}',
      );
      expect(response.statusCode, 201);
    });

    test('a wrong bearer token yields a 401 problem, not a hang or 500',
        () async {
      final response = await http.get(
        harness.baseUrl.resolve('/api/v1/vaults/default/tasks'),
        headers: {'authorization': 'Bearer definitely-wrong'},
      );
      expect(response.statusCode, 401);
      expect(
        response.headers['content-type'],
        contains('application/problem+json'),
      );
    });

    test('validation failures are 400 validation problems', () async {
      await expectLater(
        client.createTask(title: '   '),
        throwsA(_problem(400, 'problems/validation')),
      );
    });

    test('matrix_modified_asc ordering among created tasks', () async {
      final q4 = await client.createTask(title: 'sort-q4');
      final q1a = await client.createTask(
          title: 'sort-q1a', isUrgent: true, isImportant: true);
      final q2 = await client.createTask(title: 'sort-q2', isImportant: true);
      final q1b = await client.createTask(
          title: 'sort-q1b', isUrgent: true, isImportant: true);
      // Touch q1a so it becomes the most recently updated Q1 task.
      await client.updateTask(q1a.id, notes: 'touched');

      final ids = {q4.id, q1a.id, q2.id, q1b.id};
      final listed = (await client.listTasks())
          .where((t) => ids.contains(t.id))
          .map((t) => t.id)
          .toList();
      expect(listed, [q1b.id, q1a.id, q2.id, q4.id]);
    });

    test('status and quadrant filters', () async {
      final open = await client.createTask(
          title: 'filter-open', isUrgent: true, isImportant: true);
      final done = await client.createTask(title: 'filter-done');
      await client.updateTask(done.id, status: 'completed');

      final completedIds =
          (await client.listTasks(status: 'completed')).map((t) => t.id);
      expect(completedIds, contains(done.id));
      expect(completedIds, isNot(contains(open.id)));

      final q1Ids =
          (await client.listTasks(quadrant: 1)).map((t) => t.id);
      expect(q1Ids, contains(open.id));
      expect(q1Ids, isNot(contains(done.id)));
    });
  });

  group('temporal contract', () {
    test('date-only schedule round-trips as a plain date', () async {
      final created = await client.createTask(
        title: 'temporal-date',
        dueKind: 'date',
        dueDate: '2026-07-20',
      );
      expect(created.dueKind, 'date');
      expect(created.dueDate, '2026-07-20');
      expect(created.dueAtUtc, isNull);
      expect(created.timezoneId, isNull);

      final fetched = await client.getTask(created.id);
      expect(fetched.dueDate, '2026-07-20',
          reason: 'a date-only value must never shift through storage');
    });

    test('datetime schedule keeps the UTC instant and timezone', () async {
      final created = await client.createTask(
        title: 'temporal-instant',
        startKind: 'datetime',
        startAtUtc: DateTime.utc(2026, 7, 20, 20),
        timezoneId: 'America/Chicago',
        estimatedMinutes: 90,
      );
      expect(created.startAtUtc, DateTime.utc(2026, 7, 20, 20));
      expect(created.timezoneId, 'America/Chicago');
      expect(created.estimatedMinutes, 90);
    });

    test('schedule patch merges by side and clears with kind none',
        () async {
      final created = await client.createTask(
        title: 'temporal-patch',
        dueKind: 'date',
        dueDate: '2026-07-20',
      );
      final moved = await client.updateTask(created.id,
          dueDate: '2026-08-01');
      expect(moved.dueKind, 'date');
      expect(moved.dueDate, '2026-08-01');

      final cleared = await client.updateTask(moved.id, dueKind: 'none');
      expect(cleared.dueKind, 'none');
      expect(cleared.dueDate, isNull);
    });

    test('inconsistent schedules are 400 validation problems', () async {
      await expectLater(
        client.createTask(
          title: 'temporal-invalid',
          dueKind: 'datetime',
          dueAtUtc: DateTime.utc(2026, 7, 20, 20),
          // timezone_id missing
        ),
        throwsA(_problem(400, 'problems/validation')),
      );
      await expectLater(
        client.createTask(
          title: 'temporal-bad-tz',
          dueKind: 'datetime',
          dueAtUtc: DateTime.utc(2026, 7, 20, 20),
          timezoneId: 'Mars/Olympus_Mons',
        ),
        throwsA(_problem(400, 'problems/validation')),
      );
    });

    test('agenda groups by task-local date across the UTC boundary',
        () async {
      // 03:30 UTC on 2032-01-02 is 21:30 on 2032-01-01 in Chicago; the
      // far-future date keeps this test isolated from other suite tasks.
      await client.createTask(
        title: 'agenda-allday',
        dueKind: 'date',
        dueDate: '2032-01-01',
      );
      await client.createTask(
        title: 'agenda-evening',
        dueKind: 'datetime',
        dueAtUtc: DateTime.utc(2032, 1, 2, 3, 30),
        timezoneId: 'America/Chicago',
      );

      final days = await client.agenda(from: '2032-01-01', to: '2032-01-01');
      expect(days, hasLength(1));
      expect(days.single.date, '2032-01-01');
      expect(
        days.single.entries.map((e) => e.timeLocal),
        [null, '21:30'],
        reason: 'all-day first, then timed entries',
      );
    });

    test('agenda rejects inverted ranges with a 400 problem', () async {
      await expectLater(
        client.agenda(from: '2026-07-21', to: '2026-07-20'),
        throwsA(_problem(400, 'problems/validation')),
      );
    });

    test('capabilities advertise temporal and agenda features', () async {
      final capabilities = await client.capabilities();
      expect(capabilities.features, containsAll(['temporal', 'agenda']));
    });
  });

  group('tag contract', () {
    test('tag lifecycle: create, progress, rename, delete', () async {
      final tag = await client.createTag(name: 'suite-lifecycle');
      expect(tag.total, 0);

      final a = await client.createTask(title: 'tagged-a');
      final b = await client.createTask(title: 'tagged-b');
      await client.assignTag(a.id, tag.id);
      await client.assignTag(b.id, tag.id);
      await client.updateTask(a.id, status: 'completed');

      final withProgress = await client.getTag(tag.id);
      expect(withProgress.completed, 1);
      expect(withProgress.total, 2);

      final renamed = await client.updateTag(
        tag.id,
        name: 'suite-renamed',
        color: '#ABCDEF',
        ifMatchVersion: tag.version,
      );
      expect(renamed.name, 'suite-renamed');
      expect(renamed.color, '#abcdef');

      await client.deleteTag(renamed.id, ifMatchVersion: renamed.version);
      await expectLater(
        client.getTag(tag.id),
        throwsA(_problem(404, 'problems/not-found')),
      );
      // Tasks survive their tag's deletion.
      final survivor = await client.getTask(a.id);
      expect(survivor.tagIds, isNot(contains(tag.id)));
    });

    test('duplicate active tag names are 409 conflicts', () async {
      await client.createTag(name: 'suite-dup');
      await expectLater(
        client.createTag(name: 'suite-dup'),
        throwsA(_problem(409, 'problems/conflict')),
      );
    });

    test('tag task view filters and sorts', () async {
      final tag = await client.createTag(name: 'suite-view');
      final urgent = await client.createTask(
          title: 'view-urgent', isUrgent: true, isImportant: true);
      final plain = await client.createTask(title: 'view-plain');
      final other = await client.createTask(title: 'view-other');
      await client.assignTag(urgent.id, tag.id);
      await client.assignTag(plain.id, tag.id);

      final ids = (await client.tagTasks(tag.id)).map((t) => t.id).toList();
      expect(ids, [urgent.id, plain.id]);
      expect(ids, isNot(contains(other.id)));
    });

    test('tag assignment is idempotent and removal updates tag_ids',
        () async {
      final tag = await client.createTag(name: 'suite-assign');
      final task = await client.createTask(title: 'assign-target');

      final once = await client.assignTag(task.id, tag.id);
      final twice = await client.assignTag(task.id, tag.id);
      expect(twice.version, once.version, reason: 'idempotent assign');
      expect(twice.tagIds, contains(tag.id));

      final removed = await client.removeTagFromTask(task.id, tag.id);
      expect(removed.tagIds, isNot(contains(tag.id)));
    });
  });

  group('quadrant read model', () {
    test('returns all four groups with consistent counts', () async {
      await client.createTask(
          title: 'quad-q1', isUrgent: true, isImportant: true);
      await client.createTask(title: 'quad-q4');

      final groups = await client.quadrants();
      expect(groups.map((g) => g.quadrant), [1, 2, 3, 4]);
      for (final group in groups) {
        expect(group.count, group.tasks.length);
        for (final task in group.tasks) {
          expect(task.quadrant, group.quadrant);
        }
      }
    });
  });
}

TypeMatcher<ProblemDetailsException> _problem(int status, String type) =>
    isA<ProblemDetailsException>()
        .having((p) => p.status, 'status', status)
        .having((p) => p.type, 'type', type);
