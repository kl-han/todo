import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dto/health_report.dart';
import '../errors/api_exception.dart';

/// Typed client for the Quadrant Todo REST API.
///
/// One instance targets one backend. [authorization] is the full header
/// value, e.g. `Local <token>` for the embedded backend or
/// `Bearer <token>` for a standalone server.
class QuadrantApiClient {
  QuadrantApiClient({
    required this.baseUrl,
    this.authorization,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final String? authorization;
  final http.Client _http;

  Map<String, String> get _headers => {
        'authorization': ?authorization,
        'accept': 'application/json, application/problem+json',
      };

  Uri _resolve(String path) => baseUrl.resolve(path);

  /// GET /api/v1/health
  Future<HealthReport> health() async {
    final json = await _getJson('/api/v1/health');
    return HealthReport.fromJson(json);
  }

  /// Polls the health route until the backend reports ready or [timeout]
  /// elapses. Used during embedded backend startup and remote diagnostics.
  Future<HealthReport> waitUntilHealthy({
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 50),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final report = await health();
        if (report.isReady) return report;
      } on Exception catch (error) {
        lastError = error;
      }
      await Future<void>.delayed(pollInterval);
    }
    throw ApiUnavailableException(baseUrl, lastError);
  }

  Future<Map<String, Object?>> _getJson(String path) async {
    final http.Response response;
    try {
      response = await _http.get(_resolve(path), headers: _headers);
    } on http.ClientException catch (error) {
      throw ApiUnavailableException(baseUrl, error);
    }
    return _decode(response);
  }

  Map<String, Object?> _decode(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, Object?>;
    }
    if (contentType.contains('application/problem+json')) {
      throw ProblemDetailsException.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    }
    throw UnexpectedResponseException(response.statusCode, response.body);
  }

  void close() => _http.close();
}
