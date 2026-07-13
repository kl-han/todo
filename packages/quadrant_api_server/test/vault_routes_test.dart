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
    Map<String, String>? headers,
  }) async {
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

  Future<Map<String, Object?>> createTask([String title = 'task']) async {
    final response =
        await send('POST', '/api/v1/vaults/default/tasks', body: {
      'title': title,
    });
    expect(response.statusCode, 201);
    return decode(response);
  }

  group('HTTP semantics', () {
    test('created tasks carry an ETag matching their version', () async {
      final response =
          await send('POST', '/api/v1/vaults/default/tasks', body: {
        'title': 'etag',
      });
      expect(response.statusCode, 201);
      expect(response.headers['etag'], '"1"');
    });

    test('PATCH honors If-Match and returns 412 on a stale version',
        () async {
      final task = await createTask();
      final id = task['id'];

      final ok = await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {'status': 'completed'},
        headers: {'if-match': '"1"'},
      );
      expect(ok.statusCode, 200);
      expect(ok.headers['etag'], '"2"');

      final stale = await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/$id',
        body: {'title': 'other'},
        headers: {'if-match': '"1"'},
      );
      expect(stale.statusCode, 412);
      expect(
        stale.headers['content-type'],
        contains('application/problem+json'),
      );
      final problem = await decode(stale);
      expect(problem['type'], 'problems/version-conflict');
      expect(problem['current_version'], 2);
    });

    test('malformed If-Match is a 400 validation problem', () async {
      final task = await createTask();
      final response = await send(
        'PATCH',
        '/api/v1/vaults/default/tasks/${task['id']}',
        body: {'title': 'x'},
        headers: {'if-match': 'seven'},
      );
      expect(response.statusCode, 400);
      expect((await decode(response))['type'], 'problems/validation');
    });

    test('validation failures are 400 problems', () async {
      final response =
          await send('POST', '/api/v1/vaults/default/tasks', body: {
        'title': '   ',
      });
      expect(response.statusCode, 400);
      final problem = await decode(response);
      expect(problem['type'], 'problems/validation');
    });

    test('missing body fields are 400, not 500', () async {
      final response = await send(
        'POST',
        '/api/v1/vaults/default/tasks',
        body: {'notes': 'no title'},
      );
      expect(response.statusCode, 400);
    });

    test('unknown vault is a 404 problem', () async {
      final response = await send('GET', '/api/v1/vaults/nope/tasks');
      expect(response.statusCode, 404);
      expect((await decode(response))['type'], 'problems/not-found');
    });

    test('unknown query parameter values are 400 problems', () async {
      for (final query in ['status=nope', 'quadrant=9', 'sort=newest']) {
        final response =
            await send('GET', '/api/v1/vaults/default/tasks?$query');
        expect(response.statusCode, 400, reason: query);
      }
    });

    test('duplicate tag names are 409 conflict problems', () async {
      final first = await send('POST', '/api/v1/vaults/default/tags',
          body: {'name': 'home'});
      expect(first.statusCode, 201);

      final duplicate = await send('POST', '/api/v1/vaults/default/tags',
          body: {'name': 'home'});
      expect(duplicate.statusCode, 409);
      expect((await decode(duplicate))['type'], 'problems/conflict');
    });

    test('DELETE returns 204 and the task disappears from queries',
        () async {
      final task = await createTask();
      final id = task['id'];

      final deletion =
          await send('DELETE', '/api/v1/vaults/default/tasks/$id');
      expect(deletion.statusCode, 204);

      final list = await send(
          'GET', '/api/v1/vaults/default/tasks?status=all');
      final tasks = (await decode(list))['tasks'] as List<Object?>;
      expect(tasks, isEmpty);

      final single = await send('GET', '/api/v1/vaults/default/tasks/$id');
      expect(single.statusCode, 404);
    });

    test('restore brings a deleted task back', () async {
      final task = await createTask();
      final id = task['id'];
      await send('DELETE', '/api/v1/vaults/default/tasks/$id');

      final restore =
          await send('POST', '/api/v1/vaults/default/tasks/$id/restore');
      expect(restore.statusCode, 200);
      final restored = await decode(restore);
      expect(restored['deleted_at'], isNull);

      final single = await send('GET', '/api/v1/vaults/default/tasks/$id');
      expect(single.statusCode, 200);
    });

    test('tag assignment appears in tag_ids and bumps the task version',
        () async {
      final task = await createTask();
      final tagResponse = await send('POST', '/api/v1/vaults/default/tags',
          body: {'name': 'work'});
      final tag = await decode(tagResponse);

      final assign = await send(
        'PUT',
        '/api/v1/vaults/default/tasks/${task['id']}/tags/${tag['id']}',
      );
      expect(assign.statusCode, 200);
      final assigned = await decode(assign);
      expect(assigned['tag_ids'], [tag['id']]);
      expect(assigned['version'], 2);
    });

    test('quadrants read model groups tasks and counts', () async {
      await send('POST', '/api/v1/vaults/default/tasks', body: {
        'title': 'urgent+important',
        'is_urgent': true,
        'is_important': true,
      });
      await send('POST', '/api/v1/vaults/default/tasks', body: {
        'title': 'neither',
      });

      final response =
          await send('GET', '/api/v1/vaults/default/quadrants');
      expect(response.statusCode, 200);
      final body = await decode(response);
      final quadrants = (body['quadrants'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(quadrants, hasLength(4));
      expect(quadrants.first['quadrant'], 1);
      expect(quadrants.first['count'], 1);
      expect(quadrants.last['quadrant'], 4);
      expect(quadrants.last['count'], 1);
    });
  });
}
