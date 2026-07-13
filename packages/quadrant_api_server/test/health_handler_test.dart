import 'dart:convert';

import 'package:quadrant_api_server/quadrant_api_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fakes.dart';

Request _get(String path, {Map<String, String>? headers}) =>
    Request('GET', Uri.parse('http://localhost$path'), headers: headers);

Handler _handler({String? token, BackendKind kind = BackendKind.embedded}) {
  final services = inMemoryServices();
  return buildApiHandler(
    ApiServerConfig(
      backendKind: kind,
      authToken: token,
      vaults: (vaultId) => vaultId == 'default' ? services : null,
    ),
  );
}

void main() {
  group('GET /api/v1/health', () {
    test('returns readiness without authentication', () async {
      final handler = _handler(token: 'secret');

      final response = await handler(_get('/api/v1/health'));

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/json'));
      final body = jsonDecode(await response.readAsString());
      expect(body, {
        'status': 'ok',
        'api_version': 'v1',
        'schema_version': 0,
        'backend': 'embedded',
      });
    });

    test('reports the standalone backend kind', () async {
      final handler = _handler(kind: BackendKind.standalone);

      final response = await handler(_get('/api/v1/health'));
      final body = jsonDecode(await response.readAsString());
      expect(body['backend'], 'standalone');
    });
  });

  group('authentication', () {
    final handler = _handler(token: 'secret');

    test('rejects missing credentials with a 401 problem', () async {
      final response =
          await handler(_get('/api/v1/vaults/default/tasks'));

      expect(response.statusCode, 401);
      expect(
        response.headers['content-type'],
        contains('application/problem+json'),
      );
      final body = jsonDecode(await response.readAsString());
      expect(body['type'], 'problems/unauthenticated');
      expect(body['status'], 401);
    });

    test('rejects a wrong token', () async {
      final response = await handler(
        _get('/api/v1/vaults/default/tasks',
            headers: {'authorization': 'Local wrong'}),
      );
      expect(response.statusCode, 401);
    });

    test('accepts Local and Bearer schemes with the right token', () async {
      for (final scheme in ['Local', 'Bearer']) {
        final response = await handler(
          _get('/api/v1/vaults/default/tasks',
              headers: {'authorization': '$scheme secret'}),
        );
        expect(response.statusCode, 200);
      }
    });

    test('unknown routes yield a 404 problem for authenticated callers',
        () async {
      final response = await handler(
        _get('/api/v1/nowhere', headers: {'authorization': 'Local secret'}),
      );
      expect(response.statusCode, 404);
      final body = jsonDecode(await response.readAsString());
      expect(body['type'], 'problems/not-found');
    });
  });
}
