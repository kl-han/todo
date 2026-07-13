import 'dart:convert';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late Handler handler;

  setUp(() {
    final services = inMemoryServices();
    handler = buildApiHandler(
      ApiServerConfig(
        backendKind: BackendKind.embedded,
        vaults: (vaultId) => vaultId == 'default' ? services : null,
      ),
    );
  });

  Future<Response> send(
    String method,
    String path, {
    Object? body,
  }) async {
    return await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, Object?>> decode(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, Object?>;

  group('temporal task fields', () {
    test('create with a date-only due date round-trips the plain date',
        () async {
      final response = await send('POST', '/api/v1/vaults/default/tasks',
          body: {
            'title': 'due date',
            'due_kind': 'date',
            'due_date': '2026-07-20',
          });
      expect(response.statusCode, 201);
      final task = await decode(response);
      expect(task['due_kind'], 'date');
      expect(task['due_date'], '2026-07-20');
      expect(task['due_at_utc'], isNull);
      expect(task['timezone_id'], isNull);
    });

    test('create with a datetime due requires and keeps the timezone',
        () async {
      final response = await send('POST', '/api/v1/vaults/default/tasks',
          body: {
            'title': 'due instant',
            'due_kind': 'datetime',
            'due_at_utc': '2026-07-20T20:00:00Z',
            'timezone_id': 'America/Chicago',
            'estimated_minutes': 45,
          });
      expect(response.statusCode, 201);
      final task = await decode(response);
      expect(task['due_at_utc'], '2026-07-20T20:00:00.000Z');
      expect(task['timezone_id'], 'America/Chicago');
      expect(task['estimated_minutes'], 45);
    });

    test('defaults are unscheduled', () async {
      final response = await send('POST', '/api/v1/vaults/default/tasks',
          body: {'title': 'plain'});
      final task = await decode(response);
      expect(task['start_kind'], 'none');
      expect(task['due_kind'], 'none');
      expect(task['start_date'], isNull);
      expect(task['estimated_minutes'], isNull);
    });

    for (final (name, body) in [
      ('datetime without timezone', {
        'title': 't',
        'due_kind': 'datetime',
        'due_at_utc': '2026-07-20T20:00:00Z',
      }),
      ('date kind without date', {'title': 't', 'due_kind': 'date'}),
      ('unknown schedule kind', {'title': 't', 'due_kind': 'weekly'}),
      ('malformed date', {
        'title': 't',
        'due_kind': 'date',
        'due_date': '20-07-2026',
      }),
      ('impossible date', {
        'title': 't',
        'due_kind': 'date',
        'due_date': '2026-02-30',
      }),
      ('naive instant without offset', {
        'title': 't',
        'due_kind': 'datetime',
        'due_at_utc': '2026-07-20T20:00:00',
        'timezone_id': 'America/Chicago',
      }),
      ('unknown timezone', {
        'title': 't',
        'due_kind': 'datetime',
        'due_at_utc': '2026-07-20T20:00:00Z',
        'timezone_id': 'Mars/Olympus_Mons',
      }),
      ('timezone without datetime side', {
        'title': 't',
        'timezone_id': 'America/Chicago',
      }),
      ('estimate out of range', {'title': 't', 'estimated_minutes': 0}),
    ]) {
      test('rejects $name with a 400 validation problem', () async {
        final response =
            await send('POST', '/api/v1/vaults/default/tasks', body: body);
        expect(response.statusCode, 400);
        expect(response.headers['content-type'],
            contains('application/problem+json'));
      });
    }

    test('patch merges by side and clears via kind none', () async {
      final created = await decode(
        await send('POST', '/api/v1/vaults/default/tasks', body: {
          'title': 'merge',
          'due_kind': 'date',
          'due_date': '2026-07-20',
        }),
      );
      final id = created['id'];

      // Value-only patch under the existing kind.
      var patched = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {'due_date': '2026-08-01'},
      ));
      expect(patched['due_kind'], 'date');
      expect(patched['due_date'], '2026-08-01');

      // Kind change resets the side; stale values must not leak through.
      patched = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {
          'due_kind': 'datetime',
          'due_at_utc': '2026-08-01T14:00:00Z',
          'timezone_id': 'Europe/Berlin',
        },
      ));
      expect(patched['due_date'], isNull);
      expect(patched['due_at_utc'], '2026-08-01T14:00:00.000Z');

      // Clearing sheds values and the now-unused timezone.
      patched = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {'due_kind': 'none'},
      ));
      expect(patched['due_kind'], 'none');
      expect(patched['due_at_utc'], isNull);
      expect(patched['timezone_id'], isNull);
    });

    test('estimated_minutes: explicit null clears, absent leaves unchanged',
        () async {
      final created = await decode(
        await send('POST', '/api/v1/vaults/default/tasks', body: {
          'title': 'estimate',
          'estimated_minutes': 30,
        }),
      );
      final id = created['id'];

      var patched = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {'title': 'renamed'},
      ));
      expect(patched['estimated_minutes'], 30);

      patched = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {'estimated_minutes': null},
      ));
      expect(patched['estimated_minutes'], isNull);
    });
  });

  group('agenda route', () {
    test('groups by task-local date with the documented entry order',
        () async {
      await send('POST', '/api/v1/vaults/default/tasks', body: {
        'title': 'allday',
        'due_kind': 'date',
        'due_date': '2026-07-20',
      });
      await send('POST', '/api/v1/vaults/default/tasks', body: {
        'title': 'evening',
        'due_kind': 'datetime',
        // 03:30 UTC on the 21st is 22:30 on the 20th in Chicago.
        'due_at_utc': '2026-07-21T03:30:00Z',
        'timezone_id': 'America/Chicago',
      });

      final response = await send('GET',
          '/api/v1/vaults/default/agenda?from=2026-07-20&to=2026-07-20');
      expect(response.statusCode, 200);
      final report = await decode(response);
      final days = report['days'] as List<Object?>;
      expect(days, hasLength(1));
      final day = days.single as Map<String, Object?>;
      expect(day['date'], '2026-07-20');
      final entries = (day['entries'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(entries.map((e) => e['time_local']), [null, '22:30']);
      expect(entries.map((e) => e['kind']), ['due', 'due']);
    });

    test('validates its query parameters', () async {
      for (final query in [
        '', // missing both
        '?from=2026-07-20', // missing to
        '?from=2026-07-20&to=2026-07-19', // inverted
        '?from=2026-07-20&to=bad', // malformed
      ]) {
        final response =
            await send('GET', '/api/v1/vaults/default/agenda$query');
        expect(response.statusCode, 400, reason: 'query "$query"');
      }
    });
  });

  group('capabilities', () {
    test('advertise the temporal and agenda features', () async {
      final response = await send('GET', '/api/v1/capabilities');
      final body = await decode(response);
      expect(body['features'], containsAll(['temporal', 'agenda']));
    });
  });
}
