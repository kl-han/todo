import 'package:flutter/foundation.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// UI-facing state for the whole app. Every mutation goes through the
/// typed REST client — this class holds no business rules and no storage,
/// only fetched snapshots and in-flight bookkeeping.
class AppState extends ChangeNotifier {
  AppState(this._connection);

  BackendConnection _connection;

  QuadrantApiClient get _client => _connection.client;

  List<QuadrantGroupDto> quadrants = const [];
  List<TaskDto> tasks = const [];
  List<TagDto> tags = const [];

  bool loading = false;

  /// When true (default, the v2.1 behavior), activating a task row opens the
  /// editor while the checkbox toggles completion; when false, activating
  /// the row toggles completion (the pre-2.1 behavior). Same rule on every
  /// platform (see docs/src/product/task-behavior.rst).
  bool tapOpensEditor = true;

  void setTapOpensEditor(bool value) {
    if (tapOpensEditor == value) return;
    tapOpensEditor = value;
    notifyListeners();
  }

  /// Human-readable load failure; null when healthy. Remote mode shows
  /// this as an explicit offline state.
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _client.quadrants(),
        _client.listTasks(status: 'all'),
        _client.listTags(),
      ]);
      quadrants = results[0] as List<QuadrantGroupDto>;
      tasks = results[1] as List<TaskDto>;
      tags = results[2] as List<TagDto>;
    } on ApiUnavailableException {
      error = 'Backend unreachable.';
      await _recover();
    } on ProblemDetailsException catch (problem) {
      error = problem.status == 401
          ? 'Authentication failed — check the backend settings.'
          : problem.detail ?? problem.title;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(
    String title, {
    bool isUrgent = false,
    bool isImportant = false,
  }) async {
    await _mutate(() => _client.createTask(
          title: title,
          isUrgent: isUrgent,
          isImportant: isImportant,
        ));
  }

  /// Toggle completion with optimistic concurrency; a 412 means someone
  /// else changed the task, so the refresh shows the true state instead of
  /// blindly overwriting it.
  Future<void> toggleTask(TaskDto task) async {
    await _mutate(() => _client.updateTask(
          task.id,
          status: task.isCompleted ? 'open' : 'completed',
          ifMatchVersion: task.version,
        ));
  }

  Future<void> updateTask(
    TaskDto task, {
    String? title,
    String? notes,
    bool? isUrgent,
    bool? isImportant,
  }) async {
    await _mutate(() => _client.updateTask(
          task.id,
          title: title,
          notes: notes,
          isUrgent: isUrgent,
          isImportant: isImportant,
          ifMatchVersion: task.version,
        ));
  }

  /// Reclassifies a task into [quadrant] (1–4) by setting the urgency and
  /// importance flags the quadrant implies. This is the keyboard/pointer
  /// accessible alternative to Matrix drag-and-drop; quadrant membership
  /// itself is never stored (see docs/src/product/quadrant-behavior.rst).
  Future<void> moveToQuadrant(TaskDto task, int quadrant) async {
    await updateTask(
      task,
      isUrgent: quadrant == 1 || quadrant == 3,
      isImportant: quadrant == 1 || quadrant == 2,
    );
  }

  Future<void> assignTag(TaskDto task, String tagId) async {
    await _mutate(() => _client.assignTag(task.id, tagId));
  }

  Future<void> removeTag(TaskDto task, String tagId) async {
    await _mutate(() => _client.removeTagFromTask(task.id, tagId));
  }

  Future<void> deleteTask(TaskDto task) async {
    await _mutate(
        () => _client.deleteTask(task.id, ifMatchVersion: task.version));
  }

  Future<void> restoreTask(String id) async {
    await _mutate(() => _client.restoreTask(id));
  }

  Future<void> createTag(String name, {String? color}) async {
    await _mutate(() => _client.createTag(name: name, color: color));
  }

  Future<List<TaskDto>> tagTasks(String tagId, {String status = 'open'}) =>
      _client.tagTasks(tagId, status: status);

  BackendMode get mode => _connection.mode;

  /// Applies a new backend connection (mode switch from the settings
  /// sheet). The old backend is shut down; the new dataset replaces the
  /// visible one entirely — nothing is merged.
  Future<void> switchConnection(BackendConnection next) async {
    final old = _connection;
    _connection = next;
    old.client.close();
    await old.shutdown?.call();
    await refresh();
  }

  /// App resume hook: verify the embedded backend survived suspension and
  /// restart it when it did not (see backend-lifecycle docs).
  Future<void> ensureBackendHealthy() async {
    try {
      _connection = await _connection.ensureHealthy();
      if (error != null) await refresh();
    } on ApiUnavailableException {
      error = 'Backend unreachable.';
      notifyListeners();
    }
  }

  Future<void> _mutate(Future<Object?> Function() action) async {
    try {
      error = null;
      await action();
    } on ProblemDetailsException catch (problem) {
      // 412: stale version. The refresh below fetches current state; the
      // user re-applies their change deliberately.
      error = switch (problem.status) {
        412 => null,
        401 => 'Authentication failed — check the backend settings.',
        _ => problem.detail ?? problem.title,
      };
    } on ApiUnavailableException {
      error = 'Backend unreachable.';
      await _recover();
    }
    await refresh();
  }

  Future<void> _recover() async {
    try {
      _connection = await _connection.ensureHealthy();
    } on ApiUnavailableException {
      // Remote mode with the server down: stay in the explicit error
      // state; never fall back to another dataset.
    }
  }

  @override
  void dispose() {
    _connection.shutdown?.call();
    super.dispose();
  }
}
