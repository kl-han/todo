import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dto/capabilities.dart';
import '../dto/focus_session_dto.dart';
import '../dto/health_report.dart';
import '../dto/recurrence_dto.dart';
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

  /// GET /api/v1/capabilities — version and feature negotiation.
  Future<Capabilities> capabilities() async =>
      Capabilities.fromJson(await _request('GET', '/api/v1/capabilities'));

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

  /// Schedule fields follow the TaskCreate contract: pass a side's kind
  /// with exactly the value it requires (`date` → `startDate`/`dueDate`
  /// as `YYYY-MM-DD`; `datetime` → the UTC instant plus [timezoneId]).
  Future<TaskDto> createTask({
    String vault = 'default',
    required String title,
    String notes = '',
    bool isUrgent = false,
    bool isImportant = false,
    String? startKind,
    String? startDate,
    DateTime? startAtUtc,
    String? dueKind,
    String? dueDate,
    DateTime? dueAtUtc,
    String? timezoneId,
    int? estimatedMinutes,
  }) async =>
      TaskDto.fromJson(await _request(
        'POST',
        '/api/v1/vaults/$vault/tasks',
        body: {
          'title': title,
          'notes': notes,
          'is_urgent': isUrgent,
          'is_important': isImportant,
          'start_kind': ?startKind,
          'start_date': ?startDate,
          'start_at_utc': ?startAtUtc?.toUtc().toIso8601String(),
          'due_kind': ?dueKind,
          'due_date': ?dueDate,
          'due_at_utc': ?dueAtUtc?.toUtc().toIso8601String(),
          'timezone_id': ?timezoneId,
          'estimated_minutes': ?estimatedMinutes,
        },
      ));

  Future<TaskDto> getTask(String id, {String vault = 'default'}) async =>
      TaskDto.fromJson(
          await _request('GET', '/api/v1/vaults/$vault/tasks/$id'));

  /// PATCH with optimistic concurrency: pass [ifMatchVersion] to fail with
  /// a 412 [ProblemDetailsException] when the task changed underneath.
  ///
  /// Schedule fields patch by side (see the TaskPatch contract). Pass
  /// [clearEstimatedMinutes] to send an explicit null and clear the
  /// estimate.
  Future<TaskDto> updateTask(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
    String? title,
    String? notes,
    bool? isUrgent,
    bool? isImportant,
    String? status,
    String? startKind,
    String? startDate,
    DateTime? startAtUtc,
    String? dueKind,
    String? dueDate,
    DateTime? dueAtUtc,
    String? timezoneId,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
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
          'start_kind': ?startKind,
          'start_date': ?startDate,
          'start_at_utc': ?startAtUtc?.toUtc().toIso8601String(),
          'due_kind': ?dueKind,
          'due_date': ?dueDate,
          'due_at_utc': ?dueAtUtc?.toUtc().toIso8601String(),
          'timezone_id': ?timezoneId,
          if (clearEstimatedMinutes)
            'estimated_minutes': null
          else
            'estimated_minutes': ?estimatedMinutes,
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

  // ---- Focus sessions ----

  /// POST /focus-sessions — starts the timer server-side. 409 when a
  /// session is already active.
  Future<FocusSessionDto> startFocusSession({
    String vault = 'default',
    String? taskId,
    String? occurrenceId,
    String? deviceId,
    required int plannedFocusSeconds,
    int? plannedBreakSeconds,
    String? notes,
  }) async =>
      FocusSessionDto.fromJson(await _request(
        'POST',
        '/api/v1/vaults/$vault/focus-sessions',
        body: {
          'task_id': ?taskId,
          'occurrence_id': ?occurrenceId,
          'device_id': ?deviceId,
          'planned_focus_seconds': plannedFocusSeconds,
          'planned_break_seconds': ?plannedBreakSeconds,
          'notes': ?notes,
        },
      ));

  Future<List<FocusSessionDto>> listFocusSessions({
    String vault = 'default',
    bool? active,
    String? taskId,
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/focus-sessions',
      query: {
        'active': ?active?.toString(),
        'task_id': ?taskId,
      },
    );
    return [
      for (final session in json['focus_sessions'] as List<Object?>)
        FocusSessionDto.fromJson(session as Map<String, Object?>),
    ];
  }

  Future<FocusSessionDto> getFocusSession(
    String id, {
    String vault = 'default',
  }) async =>
      FocusSessionDto.fromJson(await _request(
          'GET', '/api/v1/vaults/$vault/focus-sessions/$id'));

  /// PATCH /focus-sessions/{id} — pass [action] (`pause`/`resume`) or
  /// [result] (`completed`/`cancelled`/`interrupted`), not both.
  Future<FocusSessionDto> updateFocusSession(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
    String? action,
    String? result,
    String? notes,
  }) async =>
      FocusSessionDto.fromJson(await _request(
        'PATCH',
        '/api/v1/vaults/$vault/focus-sessions/$id',
        ifMatchVersion: ifMatchVersion,
        body: {
          'action': ?action,
          'result': ?result,
          'notes': ?notes,
        },
      ));

  // ---- Recurrence ----

  /// PUT /tasks/{id}/recurrence — attach or replace the rule.
  Future<RecurrenceDto> setRecurrence(
    String taskId, {
    String vault = 'default',
    required String dtstart,
    required String rrule,
  }) async =>
      RecurrenceDto.fromJson(await _request(
        'PUT',
        '/api/v1/vaults/$vault/tasks/$taskId/recurrence',
        body: {'dtstart': dtstart, 'rrule': rrule},
      ));

  Future<RecurrenceDto> getRecurrence(
    String taskId, {
    String vault = 'default',
  }) async =>
      RecurrenceDto.fromJson(await _request(
        'GET',
        '/api/v1/vaults/$vault/tasks/$taskId/recurrence',
      ));

  Future<void> clearRecurrence(String taskId, {String vault = 'default'}) =>
      _request(
        'DELETE',
        '/api/v1/vaults/$vault/tasks/$taskId/recurrence',
        expectBody: false,
      );

  /// GET /occurrences — materializes and lists occurrences whose original
  /// date lies in `[from, to]` (`YYYY-MM-DD`, inclusive).
  Future<List<OccurrenceDto>> listOccurrences({
    String vault = 'default',
    required String from,
    required String to,
    String status = 'all',
    String? taskId,
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/occurrences',
      query: {
        'from': from,
        'to': to,
        'status': status,
        'task_id': ?taskId,
      },
    );
    return [
      for (final occurrence in json['occurrences'] as List<Object?>)
        OccurrenceDto.fromJson(occurrence as Map<String, Object?>),
    ];
  }

  Future<OccurrenceDto> getOccurrence(
    String id, {
    String vault = 'default',
  }) async =>
      OccurrenceDto.fromJson(
          await _request('GET', '/api/v1/vaults/$vault/occurrences/$id'));

  /// PATCH /occurrences/{id} — pass [status] to complete/skip/reopen, or
  /// exactly one of [occurrenceDate]/[occurrenceAtUtc] to reschedule.
  Future<OccurrenceDto> updateOccurrence(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
    String? status,
    String? occurrenceDate,
    DateTime? occurrenceAtUtc,
  }) async =>
      OccurrenceDto.fromJson(await _request(
        'PATCH',
        '/api/v1/vaults/$vault/occurrences/$id',
        ifMatchVersion: ifMatchVersion,
        body: {
          'status': ?status,
          'occurrence_date': ?occurrenceDate,
          'occurrence_at_utc': ?occurrenceAtUtc?.toUtc().toIso8601String(),
        },
      ));

  // ---- Reminders ----

  Future<ReminderDto> createReminder({
    String vault = 'default',
    String? taskId,
    String? occurrenceId,
    required String triggerType,
    DateTime? triggerAtUtc,
    int? offsetMinutes,
    String? channel,
  }) async =>
      ReminderDto.fromJson(await _request(
        'POST',
        '/api/v1/vaults/$vault/reminders',
        body: {
          'task_id': ?taskId,
          'occurrence_id': ?occurrenceId,
          'trigger_type': triggerType,
          'trigger_at_utc': ?triggerAtUtc?.toUtc().toIso8601String(),
          'offset_minutes': ?offsetMinutes,
          'channel': ?channel,
        },
      ));

  /// GET /reminders — `until` filters on the effective trigger, which the
  /// backend recomputes from the current schedule on every read (the
  /// recovery query).
  Future<List<ReminderDto>> listReminders({
    String vault = 'default',
    String state = 'all',
    DateTime? until,
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/reminders',
      query: {
        'state': state,
        'until': ?until?.toUtc().toIso8601String(),
      },
    );
    return [
      for (final reminder in json['reminders'] as List<Object?>)
        ReminderDto.fromJson(reminder as Map<String, Object?>),
    ];
  }

  Future<ReminderDto> getReminder(
    String id, {
    String vault = 'default',
  }) async =>
      ReminderDto.fromJson(
          await _request('GET', '/api/v1/vaults/$vault/reminders/$id'));

  /// PATCH /reminders/{id}. Pass [clearPlatformScheduleId] to send an
  /// explicit null (used together with `state=pending` during recovery).
  Future<ReminderDto> updateReminder(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
    String? state,
    String? platformScheduleId,
    bool clearPlatformScheduleId = false,
  }) async =>
      ReminderDto.fromJson(await _request(
        'PATCH',
        '/api/v1/vaults/$vault/reminders/$id',
        ifMatchVersion: ifMatchVersion,
        body: {
          'state': ?state,
          if (clearPlatformScheduleId)
            'platform_schedule_id': null
          else
            'platform_schedule_id': ?platformScheduleId,
        },
      ));

  Future<void> deleteReminder(
    String id, {
    String vault = 'default',
    int? ifMatchVersion,
  }) =>
      _request(
        'DELETE',
        '/api/v1/vaults/$vault/reminders/$id',
        ifMatchVersion: ifMatchVersion,
        expectBody: false,
      );

  // ---- Agenda ----

  /// GET /api/v1/vaults/{vault}/agenda — days between two task-local
  /// dates (inclusive), formatted `YYYY-MM-DD`.
  Future<List<AgendaDayDto>> agenda({
    String vault = 'default',
    required String from,
    required String to,
    String status = 'open',
  }) async {
    final json = await _request(
      'GET',
      '/api/v1/vaults/$vault/agenda',
      query: {'from': from, 'to': to, 'status': status},
    );
    return [
      for (final day in json['days'] as List<Object?>)
        AgendaDayDto.fromJson(day as Map<String, Object?>),
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
