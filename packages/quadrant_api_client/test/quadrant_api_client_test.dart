import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:test/test.dart';

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

void main() {
  group('health()', () {
    test('parses the health report and sends the Authorization header',
        () async {
      late http.Request seen;
      final client = _clientReturning(
        http.Response(
          jsonEncode({
            'status': 'ok',
            'api_version': 'v1',
            'schema_version': 3,
            'backend': 'standalone',
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
        onRequest: (request) => seen = request,
      );

      final report = await client.health();

      expect(seen.url.path, '/api/v1/health');
      expect(seen.headers['authorization'], 'Local token-value');
      expect(report.isReady, isTrue);
      expect(report.schemaVersion, 3);
      expect(report.backend, 'standalone');
    });

    test('surfaces problem+json bodies as ProblemDetailsException', () {
      final client = _clientReturning(
        http.Response(
          jsonEncode({
            'type': 'problems/unauthenticated',
            'title': 'Unauthenticated',
            'status': 401,
          }),
          401,
          headers: {'content-type': 'application/problem+json'},
        ),
      );

      expect(
        client.health(),
        throwsA(
          isA<ProblemDetailsException>()
              .having((e) => e.status, 'status', 401)
              .having((e) => e.type, 'type', 'problems/unauthenticated'),
        ),
      );
    });

    test('wraps transport failures in ApiUnavailableException', () {
      final client = QuadrantApiClient(
        baseUrl: Uri.parse('http://127.0.0.1:9'),
        httpClient: MockClient(
          (_) async => throw http.ClientException('connection refused'),
        ),
      );

      expect(client.health(), throwsA(isA<ApiUnavailableException>()));
    });

    test('treats non-problem error bodies as contract violations', () {
      final client = _clientReturning(http.Response('oops', 500));
      expect(client.health(), throwsA(isA<UnexpectedResponseException>()));
    });
  });
}
