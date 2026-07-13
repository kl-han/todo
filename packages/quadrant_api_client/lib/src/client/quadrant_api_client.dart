import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dto/health_report.dart';
import '../dto/tag_dto.dart';
import '../dto/task_dto.dart';
import '../errors/api_exception.dart';

/// Typed client for the Quadrant Todo REST API.
///
/// One instance targets one backend. [authorization] is the full header
/// value, e.g. `Local <token>` for the embedded backend or
/// `Bearer <token>` for a standalone server. Vault-scoped calls default to
/// the `default` vault, which is the embedded backend's only vault.
class QuadrantApiClient {
  QuadrantApiClient({
    required this.baseUrl,
    this.authorization,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final String? authorization;
  final http.Client _http;

  // ---- System ----

  /// GET /api/v1/health
  Future<HealthReport> health() async =>
      HealthReport.fromJson(await _request('GET', '/api/v1/health'));

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

  /// GET /api/v1/vaults — accessible vault names.
  Future<List<String>> listVaults() async {
    final json = await _request('GET', '/api/v1/vaults');
    return [
      for (final vault in json['vaults'] as List<Object?>)
        (vault as Map<String, Object?>)['id'] as String,
    ];
  }

  // ---- Tasks ----

  Future<List<TaskDto>> listTasks({
    String vault = 'default',
    String status = 'open',
    int? quadrant,
    String? tagId,
    String sort = 'matrix_modified_asc',
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/tasks',
      query: {
        'status': status,
        'quadrant': ?quadrant?.toString(),
        'tag_id': ?tagId,
        'sort': sort,
      },
    );
    return _taskList(json);
  }

  Future<TaskDto> createTask({
    String vault = 'default',
    required String title,
    String notes = '',
    bool isUrgent = false,
    bool isImportant = false,
  }) async =>
      TaskDto.fromJson(await _request(
        'POST',
        '/api/v1/vaults/$vault/tasks',
        body: {
          'title': title,
          'notes': notes,
          'is_urgent': isUrgent,
          'is_important': isImportant,
        },
      ));

  Future<TaskDto> getTask(String id, {String vault = 'default'}) async =>
      TaskDto.fromJson(
          await _request('GET', '/api/v1/vaults/$vault/tasks/$id'));

  /// PATCH with optimistic concurrency: pass [ifMatchVersion] to fail with
  /// a 412 [ProblemDetailsException] when the task changed underneath.
  Future<TaskDto> updateTask(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
    String? title,
    String? notes,
    bool? isUrgent,
    bool? isImportant,
    String? status,
  }) async =>
      TaskDto.fromJson(await _request(
        'PATCH',
        '/api/v1/vaults/$vault/tasks/$id',
        ifMatchVersion: ifMatchVersion,
        body: {
          'title': ?title,
          'notes': ?notes,
          'is_urgent': ?isUrgent,
          'is_important': ?isImportant,
          'status': ?status,
        },
      ));

  Future<void> deleteTask(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
  }) =>
      _request(
        'DELETE',
        '/api/v1/vaults/$vault/tasks/$id',
        ifMatchVersion: ifMatchVersion,
        expectBody: false,
      );

  Future<TaskDto> restoreTask(String id, {String vault = 'default'}) async =>
      TaskDto.fromJson(await _request(
        'POST',
        '/api/v1/vaults/$vault/tasks/$id/restore',
      ));

  Future<TaskDto> assignTag(
    String taskId,
    String tagId, {
    String vault = 'default',
  }) async =>
      TaskDto.fromJson(await _request(
        'PUT',
        '/api/v1/vaults/$vault/tasks/$taskId/tags/$tagId',
      ));

  Future<TaskDto> removeTagFromTask(
    String taskId,
    String tagId, {
    String vault = 'default',
  }) async =>
      TaskDto.fromJson(await _request(
        'DELETE',
        '/api/v1/vaults/$vault/tasks/$taskId/tags/$tagId',
      ));

  // ---- Quadrants ----

  Future<List<QuadrantGroupDto>> quadrants({
    String vault = 'default',
    String status = 'open',
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/quadrants',
      query: {'status': status},
    );
    return [
      for (final group in json['quadrants'] as List<Object?>)
        QuadrantGroupDto.fromJson(group as Map<String, Object?>),
    ];
  }

  // ---- Tags ----

  Future<List<TagDto>> listTags({String vault = 'default'}) async {
    final json = await _request('GET', '/api/v1/vaults/$vault/tags');
    return [
      for (final tag in json['tags'] as List<Object?>)
        TagDto.fromJson(tag as Map<String, Object?>),
    ];
  }

  Future<TagDto> createTag({
    String vault = 'default',
    required String name,
    String? color,
  }) async =>
      TagDto.fromJson(await _request(
        'POST',
        '/api/v1/vaults/$vault/tags',
        body: {'name': name, 'color': ?color},
      ));

  Future<TagDto> getTag(String id, {String vault = 'default'}) async =>
      TagDto.fromJson(
          await _request('GET', '/api/v1/vaults/$vault/tags/$id'));

  Future<TagDto> updateTag(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
    String? name,
    String? color,
  }) async =>
      TagDto.fromJson(await _request(
        'PATCH',
        '/api/v1/vaults/$vault/tags/$id',
        ifMatchVersion: ifMatchVersion,
        body: {'name': ?name, 'color': ?color},
      ));

  Future<void> deleteTag(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
  }) =>
      _request(
        'DELETE',
        '/api/v1/vaults/$vault/tags/$id',
        ifMatchVersion: ifMatchVersion,
        expectBody: false,
      );

  Future<List<TaskDto>> tagTasks(
    String tagId, {
    String vault = 'default',
    String status = 'open',
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/tags/$tagId/tasks',
      query: {'status': status},
    );
    return _taskList(json);
  }

  // ---- Transport ----

  Future<Map<String, Object?>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    int? ifMatchVersion,
    bool expectBody = true,
  }) async {
    var url = baseUrl.resolve(path);
    if (query != null && query.isNotEmpty) {
      url = url.replace(queryParameters: query);
    }
    final ifMatch = ifMatchVersion == null ? null : '"$ifMatchVersion"';
    final request = http.Request(method, url);
    request.headers.addAll({
      'authorization': ?authorization,
      'accept': 'application/json, application/problem+json',
      'if-match': ?ifMatch,
    });
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request));
    } on http.ClientException catch (error) {
      throw ApiUnavailableException(baseUrl, error);
    }
    return _decode(response, expectBody: expectBody);
  }

  Map<String, Object?> _decode(
    http.Response response, {
    required bool expectBody,
  }) {
    final contentType = response.headers['content-type'] ?? '';
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (!expectBody || response.statusCode == 204) {
        return const {};
      }
      return jsonDecode(response.body) as Map<String, Object?>;
    }
    if (contentType.contains('application/problem+json')) {
      throw ProblemDetailsException.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    }
    throw UnexpectedResponseException(response.statusCode, response.body);
  }

  List<TaskDto> _taskList(Map<String, Object?> json) => [
        for (final task in json['tasks'] as List<Object?>)
          TaskDto.fromJson(task as Map<String, Object?>),
      ];

  void close() => _http.close();
}
