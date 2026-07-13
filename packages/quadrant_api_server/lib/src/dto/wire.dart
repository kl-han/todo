import 'package:quadrant_domain/quadrant_domain.dart';

/// Wire encoding of domain objects. This is the only place task/tag JSON
/// shapes are defined server-side; the shapes are normative in
/// `api/openapi.yaml`.

String encodeInstant(DateTime time) => time.toUtc().toIso8601String();

Map<String, Object?> taskToJson(Task task, List<String> tagIds) => {
      'id': task.id,
      'title': task.title,
      'notes': task.notes,
      'is_urgent': task.isUrgent,
      'is_important': task.isImportant,
      'status': task.status.wireName,
      'quadrant': task.quadrant.number,
      'start_kind': task.schedule.startKind.wireName,
      // Plain YYYY-MM-DD; date-only values never become instants.
      'start_date': task.schedule.startDate?.toString(),
      'start_at_utc': task.schedule.startAtUtc == null
          ? null
          : encodeInstant(task.schedule.startAtUtc!),
      'due_kind': task.schedule.dueKind.wireName,
      'due_date': task.schedule.dueDate?.toString(),
      'due_at_utc': task.schedule.dueAtUtc == null
          ? null
          : encodeInstant(task.schedule.dueAtUtc!),
      'timezone_id': task.schedule.timezoneId,
      'estimated_minutes': task.estimatedMinutes,
      'completed_at':
          task.completedAt == null ? null : encodeInstant(task.completedAt!),
      'created_at': encodeInstant(task.createdAt),
      'updated_at': encodeInstant(task.updatedAt),
      'deleted_at':
          task.deletedAt == null ? null : encodeInstant(task.deletedAt!),
      'version': task.version,
      'tag_ids': tagIds,
    };

Map<String, Object?> tagToJson(Tag tag, TagProgress progress) => {
      'id': tag.id,
      'name': tag.name,
      'color': tag.color,
      'created_at': encodeInstant(tag.createdAt),
      'updated_at': encodeInstant(tag.updatedAt),
      'version': tag.version,
      'progress': {
        'completed': progress.completed,
        'total': progress.total,
      },
    };
