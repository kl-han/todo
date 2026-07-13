import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:test/test.dart';

Map<String, Object?> _taskJson({Map<String, Object?> extra = const {}}) => {
      'id': '11111111-1111-4111-8111-111111111111',
      'title': 'task',
      'notes': '',
      'is_urgent': false,
      'is_important': false,
      'status': 'open',
      'quadrant': 4,
      'start_kind': 'none',
      'start_date': null,
      'start_at_utc': null,
      'due_kind': 'none',
      'due_date': null,
      'due_at_utc': null,
      'timezone_id': null,
      'estimated_minutes': null,
      'completed_at': null,
      'created_at': '2026-07-01T00:00:00.000Z',
      'updated_at': '2026-07-01T00:00:00.000Z',
      'deleted_at': null,
      'version': 1,
      'tag_ids': <String>[],
      ...extra,
    };

QuadrantApiClient _clientReturning(http.Response response,
    {void Function(http.Request)? onRequest}) {
  return QuadrantApiClient(
    baseUrl: Uri.parse('http://127.0.0.1:9'),
    authorization: 'Local token-value',
    httpClient: MockClient((request) async {
      onRequest?.call(request);
      return response;
    }),
  );
}

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('temporal task fields', () {
    test('createTask sends schedule fields and parses them back', () async {
      late http.Request seen;
      final client = _clientReturning(
        _json(
          _taskJson(extra: {
            'due_kind': 'datetime',
            'due_at_utc': '2026-07-20T20:00:00.000Z',
            'timezone_id': 'America/Chicago',
            'estimated_minutes': 45,
          }),
          201,
        ),
        onRequest: (request) => seen = request,
      );

      final task = await client.createTask(
        title: 'task',
        dueKind: 'datetime',
        dueAtUtc: DateTime.utc(2026, 7, 20, 20),
        timezoneId: 'America/Chicago',
        estimatedMinutes: 45,
      );

      final sent = jsonDecode(seen.body) as Map<String, Object?>;
      expect(sent['due_kind'], 'datetime');
      expect(sent['due_at_utc'], '2026-07-20T20:00:00.000Z');
      expect(sent['timezone_id'], 'America/Chicago');
      expect(sent.containsKey('start_kind'), isFalse,
          reason: 'unset schedule fields are omitted');

      expect(task.dueAtUtc, DateTime.utc(2026, 7, 20, 20));
      expect(task.timezoneId, 'America/Chicago');
      expect(task.estimatedMinutes, 45);
    });

    test('clearEstimatedMinutes sends an explicit null', () async {
      late http.Request seen;
      final client = _clientReturning(
        _json(_taskJson()),
        onRequest: (request) => seen = request,
      );

      await client.updateTask(
        '11111111-1111-4111-8111-111111111111',
        clearEstimatedMinutes: true,
      );

      final sent = jsonDecode(seen.body) as Map<String, Object?>;
      expect(sent.containsKey('estimated_minutes'), isTrue);
      expect(sent['estimated_minutes'], isNull);
    });

    test('an omitted estimate is not sent at all', () async {
      late http.Request seen;
      final client = _clientReturning(
        _json(_taskJson()),
        onRequest: (request) => seen = request,
      );

      await client.updateTask(
        '11111111-1111-4111-8111-111111111111',
        title: 'renamed',
      );

      final sent = jsonDecode(seen.body) as Map<String, Object?>;
      expect(sent.containsKey('estimated_minutes'), isFalse);
    });
  });

  group('agenda()', () {
    test('sends the range and parses days and entries', () async {
      late http.Request seen;
      final client = _clientReturning(
        _json({
          'from': '2026-07-20',
          'to': '2026-07-21',
          'status': 'open',
          'days': [
            {
              'date': '2026-07-20',
              'entries': [
                {
                  'kind': 'due',
                  'time_local': null,
                  'task': _taskJson(extra: {
                    'due_kind': 'date',
                    'due_date': '2026-07-20',
                  }),
                },
                {
                  'kind': 'start',
                  'time_local': '09:30',
                  'task': _taskJson(extra: {
                    'start_kind': 'datetime',
                    'start_at_utc': '2026-07-20T14:30:00.000Z',
                    'timezone_id': 'America/Chicago',
                  }),
                },
              ],
            },
          ],
        }),
        onRequest: (request) => seen = request,
      );

      final days = await client.agenda(from: '2026-07-20', to: '2026-07-21');

      expect(seen.url.path, '/api/v1/vaults/default/agenda');
      expect(seen.url.queryParameters,
          {'from': '2026-07-20', 'to': '2026-07-21', 'status': 'open'});
      expect(days, hasLength(1));
      expect(days.single.date, '2026-07-20');
      expect(days.single.entries.first.timeLocal, isNull);
      expect(days.single.entries.last.kind, 'start');
      expect(days.single.entries.last.task.startDate, isNull);
    });
  });
}
