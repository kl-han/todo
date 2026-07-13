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
    final task = services.tasks.create(
      title: required_<String>(body, 'title'),
      notes: optional<String>(body, 'notes') ?? '',
      isUrgent: optional<bool>(body, 'is_urgent') ?? false,
      isImportant: optional<bool>(body, 'is_important') ?? false,
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
    final task = services.tasks.update(
      request.params['taskId']!,
      expectedVersion: expectedVersionFrom(request),
      title: optional<String>(body, 'title'),
      notes: optional<String>(body, 'notes'),
      isUrgent: optional<bool>(body, 'is_urgent'),
      isImportant: optional<bool>(body, 'is_important'),
      status: statusName == null ? null : _parseStatus(statusName),
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
