import 'package:http/http.dart' as http;
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';
import 'package:test/test.dart';

void main() {
  group('EmbeddedBackend', () {
    late EmbeddedBackend backend;

    setUp(() async {
      backend = await EmbeddedBackend.start();
    });

    tearDown(() => backend.stop());

    test('binds an ephemeral loopback port and serves health', () async {
      expect(backend.port, greaterThan(0));
      expect(backend.baseUrl.host, '127.0.0.1');

      final client = QuadrantApiClient(
        baseUrl: backend.baseUrl,
        authorization: backend.authorization,
      );
      final report = await client.waitUntilHealthy();
      expect(report.isReady, isTrue);
      expect(report.backend, 'embedded');
      client.close();
    });

    test('rejects requests without the launch token', () async {
      final response = await http.get(
        backend.baseUrl.resolve('/api/v1/vaults'),
      );
      expect(response.statusCode, 401);
      expect(
        response.headers['content-type'],
        contains('application/problem+json'),
      );
    });

    test('stop() shuts the server down', () async {
      await backend.stop();
      final client = QuadrantApiClient(baseUrl: backend.baseUrl);
      await expectLater(
        client.health(),
        throwsA(isA<ApiUnavailableException>()),
      );
      client.close();
      // Restart one so tearDown's stop() has something to close.
      backend = await EmbeddedBackend.start();
    });

    test('generates a fresh token per launch', () async {
      final other = await EmbeddedBackend.start();
      expect(other.token, isNot(backend.token));
      expect(backend.token.length, greaterThanOrEqualTo(43));
      await other.stop();
    });
  });

  group('LocalSessionToken', () {
    test('produces 256-bit url-safe values', () {
      final token = LocalSessionToken.generate();
      expect(token, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    });
  });
}
