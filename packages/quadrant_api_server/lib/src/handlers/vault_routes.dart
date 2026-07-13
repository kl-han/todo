import 'dart:convert';

import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../dto/wire.dart';
import '../etag.dart';
import '../middleware/problem_middleware.dart';

/// All vault-scoped data routes: tasks, quadrants, tags. HTTP translation
/// only — behavior lives in the application services.
void mountVaultRoutes(Router router, ApiServerConfig config) {
  AppServices vault(Request request) {
    final vaultId = request.params['vaultId']!;
    final services = config.vaults(vaultId);
    if (services == null) {
      throw EntityNotFoundException('No vault $vaultId.');
    }
    return services;
  }

  Response taskResponse(AppServices services, Task task, {int status = 200}) =>
      withEtag(
        _json(status, taskToJson(task, services.tasks.tagIdsOf(task.id))),
        task.version,
      );

  // ---- Tasks ----

  router.get('/api/v1/vaults/<vaultId>/tasks', (Request request) {
    final services = vault(request);
    final query = _parseTaskQuery(request.url.queryParameters);
    final tasks = services.tasks.list(query);
    return _json(200, {
      'tasks': [
        for (final task in tasks)
          taskToJson(task, services.tasks.tagIdsOf(task.id)),
      ],
    });
  });

  router.post('/api/v1/vaults/<vaultId>/tasks', (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final estimatedMinutes = optional<int>(body, 'estimated_minutes');
    final task = services.tasks.create(
      title: required_<String>(body, 'title'),
      notes: optional<String>(body, 'notes') ?? '',
      isUrgent: optional<bool>(body, 'is_urgent') ?? false,
      isImportant: optional<bool>(body, 'is_important') ?? false,
      schedule: _parseSchedulePatch(body).applyTo(const TaskSchedule.none()),
      estimatedMinutes: estimatedMinutes,
    );
    return taskResponse(services, task, status: 201);
  });

  router.get('/api/v1/vaults/<vaultId>/tasks/<taskId>', (Request request) {
    final services = vault(request);
    final task = services.tasks.get(request.params['taskId']!);
    return taskResponse(services, task);
  });

  router.patch('/api/v1/vaults/<vaultId>/tasks/<taskId>',
      (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final statusName = optional<String>(body, 'status');
    // Explicit JSON null clears estimated_minutes; an absent key leaves
    // it unchanged.
    final estimatedMinutes = body.containsKey('estimated_minutes')
        ? optional<int>(body, 'estimated_minutes')
        : null;
    final task = services.tasks.update(
      request.params['taskId']!,
      expectedVersion: expectedVersionFrom(request),
      title: optional<String>(body, 'title'),
      notes: optional<String>(body, 'notes'),
      isUrgent: optional<bool>(body, 'is_urgent'),
      isImportant: optional<bool>(body, 'is_important'),
      status: statusName == null ? null : _parseStatus(statusName),
      schedule: _parseSchedulePatch(body),
      estimatedMinutes: body.containsKey('estimated_minutes')
          ? () => estimatedMinutes
          : null,
    );
    return taskResponse(services, task);
  });

  router.delete('/api/v1/vaults/<vaultId>/tasks/<taskId>', (Request request) {
    final services = vault(request);
    services.tasks.softDelete(
      request.params['taskId']!,
      expectedVersion: expectedVersionFrom(request),
    );
    return Response(204);
  });

  router.post('/api/v1/vaults/<vaultId>/tasks/<taskId>/restore',
      (Request request) {
    final services = vault(request);
    final task = services.tasks.restore(request.params['taskId']!);
    return taskResponse(services, task);
  });

  router.put('/api/v1/vaults/<vaultId>/tasks/<taskId>/tags/<tagId>',
      (Request request) {
    final services = vault(request);
    final task = services.tasks.assignTag(
      request.params['taskId']!,
      request.params['tagId']!,
    );
    return taskResponse(services, task);
  });

  router.delete('/api/v1/vaults/<vaultId>/tasks/<taskId>/tags/<tagId>',
      (Request request) {
    final services = vault(request);
    final task = services.tasks.removeTag(
      request.params['taskId']!,
      request.params['tagId']!,
    );
    return taskResponse(services, task);
  });

  // ---- Recurrence ----

  router.put('/api/v1/vaults/<vaultId>/tasks/<taskId>/recurrence',
      (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final taskId = request.params['taskId']!;
    final rule = services.recurrence.setRecurrence(
      taskId,
      dtstart: _parseDate(required_<String>(body, 'dtstart'), 'dtstart')!,
      rrule: required_<String>(body, 'rrule'),
    );
    return _json(200, recurrenceToJson(rule, taskId));
  });

  router.get('/api/v1/vaults/<vaultId>/tasks/<taskId>/recurrence',
      (Request request) {
    final services = vault(request);
    final taskId = request.params['taskId']!;
    final rule = services.recurrence.getRecurrence(taskId);
    return _json(200, recurrenceToJson(rule, taskId));
  });

  router.delete('/api/v1/vaults/<vaultId>/tasks/<taskId>/recurrence',
      (Request request) {
    final services = vault(request);
    services.recurrence.clearRecurrence(request.params['taskId']!);
    return Response(204);
  });

  router.get('/api/v1/vaults/<vaultId>/occurrences', (Request request) {
    final services = vault(request);
    final params = request.url.queryParameters;
    final occurrences = services.recurrence.occurrences(
      from: _parseDateParam(params, 'from'),
      to: _parseDateParam(params, 'to'),
      status: _parseOccurrenceFilter(params['status'] ?? 'all'),
      taskId: params['task_id'],
    );
    return _json(200, {
      'occurrences': [
        for (final occurrence in occurrences) occurrenceToJson(occurrence),
      ],
    });
  });

  router.get('/api/v1/vaults/<vaultId>/occurrences/<occurrenceId>',
      (Request request) {
    final services = vault(request);
    final occurrence =
        services.recurrence.getOccurrence(request.params['occurrenceId']!);
    return withEtag(
        _json(200, occurrenceToJson(occurrence)), occurrence.version);
  });

  router.patch('/api/v1/vaults/<vaultId>/occurrences/<occurrenceId>',
      (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final id = request.params['occurrenceId']!;
    final expectedVersion = expectedVersionFrom(request);

    final statusName = optional<String>(body, 'status');
    final date = _parseDate(
        optional<String>(body, 'occurrence_date'), 'occurrence_date');
    final atUtc = _parseInstant(
        optional<String>(body, 'occurrence_at_utc'), 'occurrence_at_utc');
    if (statusName == null && date == null && atUtc == null) {
      throw MalformedRequestError(
        'Patch a status, an occurrence_date, or an occurrence_at_utc.',
      );
    }
    if (statusName != null && (date != null || atUtc != null)) {
      throw MalformedRequestError(
        'Patch either the status or the schedule, not both.',
      );
    }

    final occurrence = statusName != null
        ? services.recurrence.setOccurrenceStatus(
            id,
            _parseOccurrenceStatus(statusName),
            expectedVersion: expectedVersion,
          )
        : services.recurrence.rescheduleOccurrence(
            id,
            date: date,
            atUtc: atUtc,
            expectedVersion: expectedVersion,
          );
    return withEtag(
        _json(200, occurrenceToJson(occurrence)), occurrence.version);
  });

  // ---- Reminders ----

  router.get('/api/v1/vaults/<vaultId>/reminders', (Request request) {
    final services = vault(request);
    final params = request.url.queryParameters;
    final reminders = services.reminders.list(
      state: _parseReminderFilter(params['state'] ?? 'all'),
      until: _parseInstant(params['until'], 'until'),
    );
    return _json(200, {
      'reminders': [
        for (final resolved in reminders) reminderToJson(resolved),
      ],
    });
  });

  router.post('/api/v1/vaults/<vaultId>/reminders', (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final resolved = services.reminders.create(
      taskId: optional<String>(body, 'task_id'),
      occurrenceId: optional<String>(body, 'occurrence_id'),
      trigger:
          _parseReminderTrigger(required_<String>(body, 'trigger_type')),
      triggerAtUtc: _parseInstant(
          optional<String>(body, 'trigger_at_utc'), 'trigger_at_utc'),
      offsetMinutes: optional<int>(body, 'offset_minutes'),
      channel: optional<String>(body, 'channel') ?? 'notification',
    );
    return withEtag(
        _json(201, reminderToJson(resolved)), resolved.reminder.version);
  });

  router.get('/api/v1/vaults/<vaultId>/reminders/<reminderId>',
      (Request request) {
    final services = vault(request);
    final resolved = services.reminders.get(request.params['reminderId']!);
    return withEtag(
        _json(200, reminderToJson(resolved)), resolved.reminder.version);
  });

  router.patch('/api/v1/vaults/<vaultId>/reminders/<reminderId>',
      (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final stateName = optional<String>(body, 'state');
    final resolved = services.reminders.update(
      request.params['reminderId']!,
      state: stateName == null ? null : _parseReminderState(stateName),
      platformScheduleIdProvided: body.containsKey('platform_schedule_id'),
      platformScheduleId: optional<String>(body, 'platform_schedule_id'),
      expectedVersion: expectedVersionFrom(request),
    );
    return withEtag(
        _json(200, reminderToJson(resolved)), resolved.reminder.version);
  });

  router.delete('/api/v1/vaults/<vaultId>/reminders/<reminderId>',
      (Request request) {
    final services = vault(request);
    services.reminders.delete(
      request.params['reminderId']!,
      expectedVersion: expectedVersionFrom(request),
    );
    return Response(204);
  });

  // ---- Agenda read model ----

  router.get('/api/v1/vaults/<vaultId>/agenda', (Request request) {
    final services = vault(request);
    final params = request.url.queryParameters;
    final report = services.agenda.agenda(
      from: _parseDateParam(params, 'from'),
      to: _parseDateParam(params, 'to'),
      status: _parseStatusFilter(params['status'] ?? 'open'),
    );
    return _json(200, {
      'from': report.from.toString(),
      'to': report.to.toString(),
      'status': report.status,
      'days': [
        for (final day in report.days)
          {
            'date': day.date.toString(),
            'entries': [
              for (final entry in day.entries)
                {
                  'kind': entry.kind.wireName,
                  'time_local': entry.timeLocal,
                  'task': taskToJson(
                    entry.task,
                    services.tasks.tagIdsOf(entry.task.id),
                  ),
                },
            ],
          },
      ],
    });
  });

  // ---- Quadrant read model ----

  router.get('/api/v1/vaults/<vaultId>/quadrants', (Request request) {
    final services = vault(request);
    final status = _parseStatusFilter(
      request.url.queryParameters['status'] ?? 'open',
    );
    final groups = services.quadrants.grouped(status: status);
    return _json(200, {
      'status': status.name,
      'quadrants': [
        for (final group in groups)
          {
            'quadrant': group.quadrant.number,
            'count': group.count,
            'tasks': [
              for (final task in group.tasks)
                taskToJson(task, services.tasks.tagIdsOf(task.id)),
            ],
          },
      ],
    });
  });

  // ---- Tags ----

  router.get('/api/v1/vaults/<vaultId>/tags', (Request request) {
    final services = vault(request);
    return _json(200, {
      'tags': [
        for (final entry in services.tags.listWithProgress())
          tagToJson(entry.tag, entry.progress),
      ],
    });
  });

  router.post('/api/v1/vaults/<vaultId>/tags', (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final tag = services.tags.create(
      name: required_<String>(body, 'name'),
      color: optional<String>(body, 'color') ?? '#808080',
    );
    return withEtag(
      _json(201, tagToJson(tag, services.tags.progressOf(tag.id))),
      tag.version,
    );
  });

  router.get('/api/v1/vaults/<vaultId>/tags/<tagId>', (Request request) {
    final services = vault(request);
    final tag = services.tags.get(request.params['tagId']!);
    return withEtag(
      _json(200, tagToJson(tag, services.tags.progressOf(tag.id))),
      tag.version,
    );
  });

  router.patch('/api/v1/vaults/<vaultId>/tags/<tagId>',
      (Request request) async {
    final services = vault(request);
    final body = await readJsonObject(request);
    final tag = services.tags.update(
      request.params['tagId']!,
      expectedVersion: expectedVersionFrom(request),
      name: optional<String>(body, 'name'),
      color: optional<String>(body, 'color'),
    );
    return withEtag(
      _json(200, tagToJson(tag, services.tags.progressOf(tag.id))),
      tag.version,
    );
  });

  router.delete('/api/v1/vaults/<vaultId>/tags/<tagId>', (Request request) {
    final services = vault(request);
    services.tags.softDelete(
      request.params['tagId']!,
      expectedVersion: expectedVersionFrom(request),
    );
    return Response(204);
  });

  router.get('/api/v1/vaults/<vaultId>/tags/<tagId>/tasks',
      (Request request) {
    final services = vault(request);
    final status = _parseStatusFilter(
      request.url.queryParameters['status'] ?? 'open',
    );
    final tasks = services.tags.tasksOf(
      request.params['tagId']!,
      status: status,
    );
    return _json(200, {
      'tasks': [
        for (final task in tasks)
          taskToJson(task, services.tasks.tagIdsOf(task.id)),
      ],
    });
  });
}

Response _json(int status, Map<String, Object?> body) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

TaskStatus _parseStatus(String value) {
  try {
    return TaskStatus.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown status "$value".');
  }
}

StatusFilter _parseStatusFilter(String value) {
  try {
    return StatusFilter.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown status filter "$value".');
  }
}

TaskQuery _parseTaskQuery(Map<String, String> params) {
  Quadrant? quadrant;
  final rawQuadrant = params['quadrant'];
  if (rawQuadrant != null) {
    final number = int.tryParse(rawQuadrant);
    if (number == null || number < 1 || number > 4) {
      throw MalformedRequestError('quadrant must be 1-4.');
    }
    quadrant = Quadrant.fromNumber(number);
  }
  final rawSort = params['sort'];
  final sort = rawSort == null
      ? TaskSort.matrixModifiedAsc
      : _parseSort(rawSort);
  return TaskQuery(
    status: _parseStatusFilter(params['status'] ?? 'open'),
    quadrant: quadrant,
    tagId: params['tag_id'],
    sort: sort,
  );
}

TaskSort _parseSort(String value) {
  try {
    return TaskSort.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown sort "$value".');
  }
}

OccurrenceFilter _parseOccurrenceFilter(String value) {
  try {
    return OccurrenceFilter.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown occurrence status "$value".');
  }
}

OccurrenceStatus _parseOccurrenceStatus(String value) {
  try {
    return OccurrenceStatus.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown occurrence status "$value".');
  }
}

ReminderFilter _parseReminderFilter(String value) {
  try {
    return ReminderFilter.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown reminder state "$value".');
  }
}

ReminderState _parseReminderState(String value) {
  try {
    return ReminderState.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown reminder state "$value".');
  }
}

ReminderTrigger _parseReminderTrigger(String value) {
  try {
    return ReminderTrigger.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown trigger type "$value".');
  }
}

/// Parses the schedule fields shared by TaskCreate and TaskPatch. The
/// cross-field rules are enforced by the domain after merging; this only
/// converts wire values, with 400s for shapes that cannot parse.
SchedulePatch _parseSchedulePatch(Map<String, Object?> body) => SchedulePatch(
      startKind: _parseKind(optional<String>(body, 'start_kind')),
      startDate: _parseDate(optional<String>(body, 'start_date'), 'start_date'),
      startAtUtc:
          _parseInstant(optional<String>(body, 'start_at_utc'), 'start_at_utc'),
      dueKind: _parseKind(optional<String>(body, 'due_kind')),
      dueDate: _parseDate(optional<String>(body, 'due_date'), 'due_date'),
      dueAtUtc:
          _parseInstant(optional<String>(body, 'due_at_utc'), 'due_at_utc'),
      timezoneId: optional<String>(body, 'timezone_id'),
    );

ScheduleKind? _parseKind(String? value) {
  if (value == null) return null;
  try {
    return ScheduleKind.fromWire(value);
  } on ArgumentError {
    throw MalformedRequestError('Unknown schedule kind "$value".');
  }
}

PlainDate? _parseDate(String? value, String field) {
  if (value == null) return null;
  try {
    return PlainDate.parse(value);
  } on DomainValidationError catch (error) {
    throw MalformedRequestError('Field "$field": ${error.message}');
  }
}

PlainDate _parseDateParam(Map<String, String> params, String name) {
  final value = params[name];
  if (value == null) {
    throw MalformedRequestError('Query parameter "$name" is required.');
  }
  return _parseDate(value, name)!;
}

/// Instants must carry an explicit UTC designator or offset; a naive
/// local time would silently mean "server timezone", which no request is
/// allowed to depend on.
DateTime? _parseInstant(String? value, String field) {
  if (value == null) return null;
  final hasDesignator =
      value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
  final DateTime? parsed = DateTime.tryParse(value);
  if (!hasDesignator || parsed == null) {
    throw MalformedRequestError(
      'Field "$field" must be an RFC 3339 instant with a UTC designator '
      'or offset.',
    );
  }
  return parsed.toUtc();
}
