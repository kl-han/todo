import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:test/test.dart';

import 'harness.dart';

/// The backend contract, written once and executed against every harness.
///
/// Everything asserted here is normative API behavior from
/// `api/openapi.yaml`; anything backend-specific is limited to the
/// `backend` field of the health report.
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
      expect(report.schemaVersion, isNonNegative);
      expect(report.backend, harness.expectedBackendKind);
      anonymous.close();
    });

    test('data routes reject missing credentials with a 401 problem',
        () async {
      final response = await http.get(
        harness.baseUrl.resolve('/api/v1/vaults'),
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
  });
}
