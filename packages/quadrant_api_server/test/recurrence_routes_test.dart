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

  Future<Response> send(String method, String path,
      {Object? body, Map<String, String>? headers}) async {
    return await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
        headers: headers,
      ),
    );
  }

  Future<Map<String, Object?>> decode(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, Object?>;

  Future<Map<String, Object?>> createDueDateTask() async => decode(
        await send('POST', '/api/v1/vaults/default/tasks', body: {
          'title': 'recurring',
          'due_kind': 'date',
          'due_date': '2026-07-06',
        }),
      );

  group('recurrence routes', () {
    test('PUT attaches a rule and the task exposes its id', () async {
      final task = await createDueDateTask();
      final response = await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${task['id']}/recurrence',
        body: {'dtstart': '2026-07-06', 'rrule': 'FREQ=WEEKLY;BYDAY=MO'},
      );
      expect(response.statusCode, 200);
      final rule = await decode(response);
      expect(rule['rrule'], 'FREQ=WEEKLY;BYDAY=MO');
      expect(rule['task_id'], task['id']);

      final fetched = await decode(
          await send('GET', '/api/v1/vaults/default/tasks/${task['id']}'));
      expect(fetched['recurrence_rule_id'], rule['id']);
    });

    test('GET/DELETE lifecycle with 404 for non-recurring tasks', () async {
      final task = await createDueDateTask();
      final missing = await send(
          'GET', '/api/v1/vaults/default/tasks/${task['id']}/recurrence');
      expect(missing.statusCode, 404);

      await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${task['id']}/recurrence',
        body: {'dtstart': '2026-07-06', 'rrule': 'FREQ=DAILY'},
      );
      expect(
        (await send('GET',
                '/api/v1/vaults/default/tasks/${task['id']}/recurrence'))
            .statusCode,
        200,
      );
      expect(
        (await send('DELETE',
                '/api/v1/vaults/default/tasks/${task['id']}/recurrence'))
            .statusCode,
        204,
      );
      // Idempotent.
      expect(
        (await send('DELETE',
                '/api/v1/vaults/default/tasks/${task['id']}/recurrence'))
            .statusCode,
        204,
      );
    });

    test('rejects invalid rules and unscheduled tasks with 400', () async {
      final unscheduled = await decode(await send(
          'POST', '/api/v1/vaults/default/tasks',
          body: {'title': 'no schedule'}));
      final noAnchor = await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${unscheduled['id']}/recurrence',
        body: {'dtstart': '2026-07-06', 'rrule': 'FREQ=DAILY'},
      );
      expect(noAnchor.statusCode, 400);

      final task = await createDueDateTask();
      final badRule = await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${task['id']}/recurrence',
        body: {'dtstart': '2026-07-06', 'rrule': 'FREQ=YEARLY'},
      );
      expect(badRule.statusCode, 400);
    });

    test('occurrence listing, completion, and exception round-trip',
        () async {
      final task = await createDueDateTask();
      await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${task['id']}/recurrence',
        body: {'dtstart': '2026-07-06', 'rrule': 'FREQ=WEEKLY;BYDAY=MO'},
      );

      final listed = await decode(await send(
        'GET',
        '/api/v1/vaults/default/occurrences'
        '?from=2026-07-06&to=2026-07-20&task_id=${task['id']}',
      ));
      final occurrences =
          (listed['occurrences'] as List<Object?>).cast<Map<String, Object?>>();
      expect(occurrences.map((o) => o['original_date']),
          ['2026-07-06', '2026-07-13', '2026-07-20']);
      expect(occurrences.first['kind'], 'due');
      expect(occurrences.first['occurrence_date'], '2026-07-06');

      final first = occurrences.first;
      final completed = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/occurrences/${first['id']}',
        body: {'status': 'completed'},
        headers: {'if-match': '"1"'},
      ));
      expect(completed['status'], 'completed');
      expect(completed['completed_at'], isNotNull);

      // Reschedule the second; identity stays.
      final second = occurrences[1];
      final moved = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/occurrences/${second['id']}',
        body: {'occurrence_date': '2026-07-15'},
      ));
      expect(moved['occurrence_date'], '2026-07-15');
      expect(moved['original_date'], '2026-07-13');

      // Filters see the settled statuses.
      final open = await decode(await send(
        'GET',
        '/api/v1/vaults/default/occurrences'
        '?from=2026-07-06&to=2026-07-20&status=open',
      ));
      expect((open['occurrences'] as List<Object?>).length, 2);
    });

    test('occurrence patch validation', () async {
      final task = await createDueDateTask();
      await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${task['id']}/recurrence',
        body: {'dtstart': '2026-07-06', 'rrule': 'FREQ=DAILY;COUNT=1'},
      );
      final listed = await decode(await send('GET',
          '/api/v1/vaults/default/occurrences?from=2026-07-06&to=2026-07-06'));
      final id =
          ((listed['occurrences'] as List<Object?>).single as Map)['id'];

      // Empty patch, status+schedule together, wrong-kind reschedule,
      // stale If-Match.
      expect(
        (await send('PATCH', '/api/v1/vaults/default/occurrences/$id',
                body: {}))
            .statusCode,
        400,
      );
      expect(
        (await send('PATCH', '/api/v1/vaults/default/occurrences/$id',
                body: {'status': 'completed', 'occurrence_date': '2026-07-07'}))
            .statusCode,
        400,
      );
      expect(
        (await send('PATCH', '/api/v1/vaults/default/occurrences/$id', body: {
          'occurrence_at_utc': '2026-07-07T10:00:00Z',
        }))
            .statusCode,
        400,
        reason: 'date-kind occurrence cannot take an instant',
      );
      expect(
        (await send('PATCH', '/api/v1/vaults/default/occurrences/$id',
                body: {'status': 'completed'},
                headers: {'if-match': '"9"'}))
            .statusCode,
        412,
      );
    });
  });

  group('reminder routes', () {
    Future<Map<String, Object?>> createInstantTask() async => decode(
          await send('POST', '/api/v1/vaults/default/tasks', body: {
            'title': 'remind me',
            'due_kind': 'datetime',
            'due_at_utc': '2026-07-20T20:00:00Z',
            'timezone_id': 'UTC',
          }),
        );

    test('relative reminder lifecycle with recomputed trigger', () async {
      final task = await createInstantTask();
      final created = await decode(await send(
        'POST',
        '/api/v1/vaults/default/reminders',
        body: {
          'task_id': task['id'],
          'trigger_type': 'relative_due',
          'offset_minutes': 30,
        },
      ));
      expect(created['state'], 'pending');
      expect(created['effective_trigger_at_utc'], '2026-07-20T19:30:00.000Z');

      // Move the task's due; the reminder follows on the next read.
      await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/${task['id']}',
        body: {'due_at_utc': '2026-07-21T20:00:00Z'},
      );
      final read = await decode(await send(
          'GET', '/api/v1/vaults/default/reminders/${created['id']}'));
      expect(read['effective_trigger_at_utc'], '2026-07-21T19:30:00.000Z');

      // Platform adapter records its schedule, then recovery resets it.
      final scheduled = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/reminders/${created['id']}',
        body: {'state': 'scheduled', 'platform_schedule_id': 'os-1'},
      ));
      expect(scheduled['platform_schedule_id'], 'os-1');
      final recovered = await decode(await send(
        'PATCH',
        '/api/v1/vaults/default/reminders/${created['id']}',
        body: {'state': 'pending'},
      ));
      expect(recovered['platform_schedule_id'], isNull);

      expect(
        (await send('DELETE',
                '/api/v1/vaults/default/reminders/${created['id']}'))
            .statusCode,
        204,
      );
    });

    test('horizon query returns pending reminders in trigger order',
        () async {
      final task = await createInstantTask();
      await send('POST', '/api/v1/vaults/default/reminders', body: {
        'task_id': task['id'],
        'trigger_type': 'absolute',
        'trigger_at_utc': '2026-07-22T09:00:00Z',
      });
      await send('POST', '/api/v1/vaults/default/reminders', body: {
        'task_id': task['id'],
        'trigger_type': 'absolute',
        'trigger_at_utc': '2026-07-18T09:00:00Z',
      });

      final horizon = await decode(await send(
        'GET',
        '/api/v1/vaults/default/reminders'
        '?state=pending&until=2026-07-19T00:00:00Z',
      ));
      final reminders = (horizon['reminders'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(reminders, hasLength(1));
      expect(reminders.single['effective_trigger_at_utc'],
          '2026-07-18T09:00:00.000Z');
    });

    test('validation failures are 400/404 problems', () async {
      final task = await createInstantTask();
      // Relative without offset.
      expect(
        (await send('POST', '/api/v1/vaults/default/reminders', body: {
          'task_id': task['id'],
          'trigger_type': 'relative_due',
        }))
            .statusCode,
        400,
      );
      // Unknown trigger type.
      expect(
        (await send('POST', '/api/v1/vaults/default/reminders', body: {
          'task_id': task['id'],
          'trigger_type': 'sometimes',
          'offset_minutes': 5,
        }))
            .statusCode,
        400,
      );
      // Dangling task reference.
      expect(
        (await send('POST', '/api/v1/vaults/default/reminders', body: {
          'task_id': '99999999-9999-4999-8999-999999999999',
          'trigger_type': 'absolute',
          'trigger_at_utc': '2026-07-18T09:00:00Z',
        }))
            .statusCode,
        404,
      );
    });
  });
}
