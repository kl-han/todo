import 'dart:io';

import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_store/quadrant_store.dart';

/// Multi-vault registry for the standalone server: one SQLite file per
/// vault under `<dataDir>/<name>.sqlite3`, opened lazily and cached.
///
/// Vault names map directly to file names, so they are validated
/// strictly — lowercase alphanumerics, `-` and `_`, 1–64 characters —
/// which structurally rules out path traversal.
class VaultManager {
  VaultManager(this.dataDir);

  final String dataDir;
  final Map<String, _OpenVault> _open = {};

  static final RegExp _validName = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

  static bool isValidName(String name) => _validName.hasMatch(name);

  String pathFor(String name) => '$dataDir/$name.sqlite3';

  /// Creates a new empty vault. Fails if the name is invalid or the vault
  /// already exists.
  void create(String name) {
    if (!isValidName(name)) {
      throw ArgumentError.value(name, 'name', 'invalid vault name');
    }
    final file = File(pathFor(name));
    if (file.existsSync()) {
      throw StateError('Vault "$name" already exists.');
    }
    QuadrantDatabase.open(file.path).close();
  }

  /// Existing vault names, `default` first, rest alphabetical.
  List<String> list() {
    final dir = Directory(dataDir);
    if (!dir.existsSync()) return const ['default'];
    final names = [
      for (final entity in dir.listSync())
        if (entity is File && entity.path.endsWith('.sqlite3'))
          entity.uri.pathSegments.last.replaceFirst('.sqlite3', ''),
    ].where(isValidName).toSet()
      ..add('default');
    final sorted = names.toList()..sort();
    return ['default', ...sorted.where((n) => n != 'default')];
  }

  /// Application services for a vault, or null when it does not exist.
  /// `default` is created on first access; other vaults must be created
  /// explicitly so a typo in a URL cannot mint an empty dataset.
  AppServices? resolve(String name) {
    final open = _open[name];
    if (open != null) return open.services;

    if (!isValidName(name)) return null;
    final exists = File(pathFor(name)).existsSync();
    if (!exists && name != 'default') return null;

    final database = QuadrantDatabase.open(pathFor(name));
    final services = AppServices(
      taskRepository: SqliteTaskRepository(database),
      tagRepository: SqliteTagRepository(database),
      recurrenceRepository: SqliteRecurrenceRepository(database),
      reminderRepository: SqliteReminderRepository(database),
      focusSessionRepository: SqliteFocusSessionRepository(database),
      planningRepository: SqlitePlanningRepository(database),
      reportRepository: SqliteReportRepository(database),
    );
    _open[name] = _OpenVault(database, services);
    return services;
  }

  void closeAll() {
    for (final vault in _open.values) {
      vault.database.close();
    }
    _open.clear();
  }
}

class _OpenVault {
  _OpenVault(this.database, this.services);

  final QuadrantDatabase database;
  final AppServices services;
}
