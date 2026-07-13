import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/quadrant_database.dart';
import '../database/time_codec.dart';

/// SQLite-backed [TagRepository].
class SqliteTagRepository implements TagRepository {
  SqliteTagRepository(QuadrantDatabase database) : _db = database.db;

  final Database _db;

  @override
  Tag? findById(String id) {
    final rows = _db.select('SELECT * FROM tags WHERE id = ?', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Tag? findActiveByName(String name) {
    final rows = _db.select(
      'SELECT * FROM tags WHERE name = ? AND deleted_at IS NULL',
      [name],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  List<Tag> listActive() {
    final rows = _db.select(
      'SELECT * FROM tags WHERE deleted_at IS NULL ORDER BY name',
    );
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  TagProgress progressOf(String tagId) {
    final row = _db.select(
      'SELECT COUNT(*) AS total, '
      'COALESCE(SUM(CASE WHEN t.completed_at IS NOT NULL THEN 1 ELSE 0 END), 0) '
      '  AS completed '
      'FROM tasks t JOIN task_tags tt ON tt.task_id = t.id '
      'WHERE tt.tag_id = ? AND t.deleted_at IS NULL',
      [tagId],
    ).first;
    return TagProgress(
      completed: row['completed'] as int,
      total: row['total'] as int,
    );
  }

  @override
  void insert(Tag tag) {
    _db.execute(
      'INSERT INTO tags (id, name, color, created_at, updated_at, '
      'deleted_at, version) VALUES (?, ?, ?, ?, ?, ?, ?)',
      _toRow(tag),
    );
  }

  @override
  void update(Tag tag) {
    _db.execute(
      'UPDATE tags SET name = ?, color = ?, created_at = ?, updated_at = ?, '
      'deleted_at = ?, version = ? WHERE id = ?',
      [..._toRow(tag).sublist(1), tag.id],
    );
  }

  static List<Object?> _toRow(Tag tag) => [
        tag.id,
        tag.name,
        tag.color,
        encodeTime(tag.createdAt),
        encodeTime(tag.updatedAt),
        tag.deletedAt == null ? null : encodeTime(tag.deletedAt!),
        tag.version,
      ];

  static Tag _fromRow(Row row) => Tag(
        id: row['id'] as String,
        name: row['name'] as String,
        color: row['color'] as String,
        createdAt: decodeTime(row['created_at'] as String),
        updatedAt: decodeTime(row['updated_at'] as String),
        deletedAt: decodeTimeOrNull(row['deleted_at']),
        version: row['version'] as int,
      );
}
