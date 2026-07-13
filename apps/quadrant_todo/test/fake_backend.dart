import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// A tiny in-memory fake of the v1 contract for widget tests: enough of
/// tasks/tags/quadrants to drive the UI without sockets. Contract fidelity
/// is guaranteed elsewhere (conformance suite); this exists so widget
/// tests are fast and deterministic.
class FakeBackend {
  final List<Map<String, Object?>> tasks = [];
  final List<Map<String, Object?>> tags = [];
  int _nextId = 0;

  /// When true every request fails at the transport level, driving the
  /// explicit offline/error state.
  bool unreachable = false;

  /// Body of the most recent task PATCH, for editor assertions.
  Map<String, Object?>? lastPatch;

  BackendConnection connection() => BackendConnection(
        mode: BackendMode.local,
        client: QuadrantApiClient(
          baseUrl: Uri.parse('http://fake.local'),
          httpClient: MockClient(_handle),
        ),
      );

  Map<String, Object?> addTask(
    String title, {
    bool urgent = false,
    bool important = false,
  }) {
    final now = DateTime.utc(2026, 1, 1).toIso8601String();
    final task = <String, Object?>{
      'id': 'task-${_nextId++}',
      'title': title,
      'notes': '',
      'is_urgent': urgent,
      'is_important': important,
      'status': 'open',
      'quadrant': _quadrant(urgent, important),
      'completed_at': null,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'version': 1,
      'tag_ids': const <String>[],
    };
    tasks.add(task);
    return task;
  }

  static int _quadrant(bool urgent, bool important) {
    if (urgent && important) return 1;
    if (important) return 2;
    if (urgent) return 3;
    return 4;
  }

  Future<http.Response> _handle(http.Request request) async {
    if (unreachable) throw http.ClientException('connection refused');
    final path = request.url.path;
    final method = request.method;

    if (path == '/api/v1/health') {
      return _ok({
        'status': 'ok',
        'api_version': 'v1',
        'schema_version': 1,
        'backend': 'embedded',
      });
    }
    if (path == '/api/v1/vaults/default/quadrants') {
      final live = tasks.where((t) => t['deleted_at'] == null);
      return _ok({
        'status': 'open',
        'quadrants': [
          for (var q = 1; q <= 4; q++)
            {
              'quadrant': q,
              'count': live
                  .where((t) => t['quadrant'] == q && t['status'] == 'open')
                  .length,
              'tasks': [
                ...live.where(
                    (t) => t['quadrant'] == q && t['status'] == 'open'),
              ],
            },
        ],
      });
    }
    if (path == '/api/v1/vaults/default/tasks' && method == 'GET') {
      return _ok({
        'tasks': [...tasks.where((t) => t['deleted_at'] == null)],
      });
    }
    if (path == '/api/v1/vaults/default/tasks' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final task = addTask(
        body['title'] as String,
        urgent: body['is_urgent'] as bool? ?? false,
        important: body['is_important'] as bool? ?? false,
      );
      return _ok(task, status: 201);
    }
    final taskMatch =
        RegExp(r'^/api/v1/vaults/default/tasks/([^/]+)$').firstMatch(path);
    if (taskMatch != null && method == 'PATCH') {
      final task = tasks.firstWhere((t) => t['id'] == taskMatch.group(1));
      final body = jsonDecode(request.body) as Map<String, Object?>;
      lastPatch = body;
      for (final field in ['title', 'notes', 'is_urgent', 'is_important']) {
        if (body.containsKey(field)) task[field] = body[field];
      }
      if (body case {'status': final String status}) {
        task['status'] = status;
        task['completed_at'] =
            status == 'completed' ? DateTime.now().toIso8601String() : null;
      }
      task['quadrant'] = _quadrant(
        task['is_urgent'] as bool,
        task['is_important'] as bool,
      );
      task['version'] = (task['version'] as int) + 1;
      return _ok(task);
    }
    final restoreMatch =
        RegExp(r'^/api/v1/vaults/default/tasks/([^/]+)/restore$')
            .firstMatch(path);
    if (restoreMatch != null && method == 'POST') {
      final task = tasks.firstWhere((t) => t['id'] == restoreMatch.group(1));
      task['deleted_at'] = null;
      task['version'] = (task['version'] as int) + 1;
      return _ok(task);
    }
    if (taskMatch != null && method == 'DELETE') {
      final task = tasks.firstWhere((t) => t['id'] == taskMatch.group(1));
      task['deleted_at'] = DateTime.now().toIso8601String();
      task['version'] = (task['version'] as int) + 1;
      return http.Response('', 204);
    }
    final tagAssign = RegExp(
            r'^/api/v1/vaults/default/tasks/([^/]+)/tags/([^/]+)$')
        .firstMatch(path);
    if (tagAssign != null) {
      final task = tasks.firstWhere((t) => t['id'] == tagAssign.group(1));
      final ids = {...(task['tag_ids'] as List<Object?>).cast<String>()};
      method == 'PUT'
          ? ids.add(tagAssign.group(2)!)
          : ids.remove(tagAssign.group(2));
      task['tag_ids'] = ids.toList();
      return _ok(task);
    }
    if (path == '/api/v1/vaults/default/tags' && method == 'GET') {
      return _ok({'tags': tags});
    }
    if (path == '/api/v1/vaults/default/tags' && method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final now = DateTime.utc(2026, 1, 1).toIso8601String();
      final tag = <String, Object?>{
        'id': 'tag-${_nextId++}',
        'name': body['name'],
        'color': body['color'] ?? '#808080',
        'created_at': now,
        'updated_at': now,
        'version': 1,
        'progress': {'completed': 0, 'total': 0},
      };
      tags.add(tag);
      return _ok(tag, status: 201);
    }
    final tagTasks = RegExp(r'^/api/v1/vaults/default/tags/([^/]+)/tasks$')
        .firstMatch(path);
    if (tagTasks != null) {
      return _ok({'tasks': const <Object?>[]});
    }
    return http.Response(
      jsonEncode({
        'type': 'problems/not-found',
        'title': 'Not Found',
        'status': 404,
      }),
      404,
      headers: {'content-type': 'application/problem+json'},
    );
  }

  http.Response _ok(Map<String, Object?> body, {int status = 200}) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
}
