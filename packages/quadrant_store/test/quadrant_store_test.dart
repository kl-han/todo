import 'dart:io';

import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:quadrant_store/quadrant_store.dart';
import 'package:test/test.dart';

void main() {
  late QuadrantDatabase db;
  late SqliteTaskRepository tasks;
  late SqliteTagRepository tags;

  setUp(() {
    db = QuadrantDatabase.inMemory();
    tasks = SqliteTaskRepository(db);
    tags = SqliteTagRepository(db);
  });

  tearDown(() => db.close());

  Task makeTask({
    String title = 'task',
    bool urgent = false,
    bool important = false,
    DateTime? updatedAt,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    final task = Task(
      id: EntityId.generate(),
      title: title,
      notes: '',
      isUrgent: urgent,
      isImportant: important,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
    tasks.insert(task);
    return task;
  }

  group('migrations', () {
    test('bring a fresh database to the current schema version', () {
      expect(db.userVersion, schemaVersion);
    });

    test('are idempotent on reopen', () {
      db.migrate();
      expect(db.userVersion, schemaVersion);
    });

    test('refuse databases from a newer build', () {
      db.db.execute('PRAGMA user_version = ${schemaVersion + 1}');
      expect(db.migrate, throwsStateError);
    });
  });

  group('task repository', () {
    test('round-trips all fields', () {
      final original = Task(
        id: EntityId.generate(),
        title: 'full',
        notes: 'notes',
        isUrgent: true,
        isImportant: true,
        createdAt: DateTime.utc(2026, 1, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2, 2, 3, 4, 5, 6),
        completedAt: DateTime.utc(2026, 1, 3),
        version: 7,
      );
      tasks.insert(original);
      final loaded = tasks.findById(original.id)!;
      expect(loaded.title, 'full');
      expect(loaded.notes, 'notes');
      expect(loaded.isUrgent, isTrue);
      expect(loaded.updatedAt, original.updatedAt);
      expect(loaded.completedAt, original.completedAt);
      expect(loaded.version, 7);
    });

    test('round-trips schedule fields', () {
      final original = Task(
        id: EntityId.generate(),
        title: 'scheduled',
        notes: '',
        isUrgent: false,
        isImportant: false,
        schedule: TaskSchedule(
          startKind: ScheduleKind.date,
          startDate: PlainDate.parse('2026-07-19'),
          dueKind: ScheduleKind.datetime,
          dueAtUtc: DateTime.utc(2026, 7, 20, 20),
          timezoneId: 'America/Chicago',
        ),
        estimatedMinutes: 90,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      tasks.insert(original);
      final loaded = tasks.findById(original.id)!;
      expect(loaded.schedule.startKind, ScheduleKind.date);
      expect(loaded.schedule.startDate, PlainDate.parse('2026-07-19'));
      expect(loaded.schedule.startAtUtc, isNull);
      expect(loaded.schedule.dueKind, ScheduleKind.datetime);
      expect(loaded.schedule.dueAtUtc, DateTime.utc(2026, 7, 20, 20));
      expect(loaded.schedule.timezoneId, 'America/Chicago');
      expect(loaded.estimatedMinutes, 90);
    });

    test('stores date-only values as plain dates, not instants', () {
      final original = Task(
        id: EntityId.generate(),
        title: 'date-only',
        notes: '',
        isUrgent: false,
        isImportant: false,
        schedule: TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      tasks.insert(original);
      final raw = db.db
          .select('SELECT due_date FROM tasks WHERE id = ?', [original.id])
          .first['due_date'];
      expect(raw, '2026-07-20');
    });

    test('scheduled() returns only scheduled, status-matching tasks', () {
      makeTask(title: 'unscheduled');
      final due = Task(
        id: EntityId.generate(),
        title: 'due',
        notes: '',
        isUrgent: false,
        isImportant: false,
        schedule: TaskSchedule(
          dueKind: ScheduleKind.date,
          dueDate: PlainDate.parse('2026-07-20'),
        ),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      tasks.insert(due);
      tasks.update(due.complete(DateTime.utc(2026, 1, 2)));

      expect(tasks.scheduled(StatusFilter.open), isEmpty);
      expect(
        tasks.scheduled(StatusFilter.completed).map((t) => t.title),
        ['due'],
      );
      expect(tasks.scheduled(StatusFilter.all), hasLength(1));
    });

    test('applies the matrix_modified_asc sort', () {
      final q4 = makeTask(title: 'q4');
      final q1old = makeTask(
        title: 'q1-old',
        urgent: true,
        important: true,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final q1new = makeTask(
        title: 'q1-new',
        urgent: true,
        important: true,
        updatedAt: DateTime.utc(2026, 1, 5),
      );
      final q2 = makeTask(title: 'q2', important: true);
      final q3 = makeTask(title: 'q3', urgent: true);

      // The normative sort is `is_urgent DESC, is_important DESC,
      // updated_at ASC, id ASC`, so urgent-only (Q3) ranks above
      // important-only (Q2).
      final ordered = tasks.query(const TaskQuery()).map((t) => t.id);
      expect(
        ordered,
        [q1old.id, q1new.id, q3.id, q2.id, q4.id],
      );
    });

    test('filters by status, quadrant, and tag', () {
      final open = makeTask(title: 'open', urgent: true, important: true);
      final done = makeTask(title: 'done');
      tasks.update(done.complete(DateTime.utc(2026, 2, 1)));

      expect(
        tasks.query(const TaskQuery()).map((t) => t.id),
        [open.id],
      );
      expect(
        tasks
            .query(const TaskQuery(status: StatusFilter.completed))
            .map((t) => t.id),
        [done.id],
      );
      expect(
        tasks.query(const TaskQuery(status: StatusFilter.all)).length,
        2,
      );
      expect(
        tasks
            .query(const TaskQuery(quadrant: Quadrant.q1))
            .map((t) => t.id),
        [open.id],
      );
    });

    test('excludes soft-deleted tasks from queries but keeps the row', () {
      final task = makeTask();
      tasks.update(task.softDelete(DateTime.utc(2026, 2, 1)));
      expect(tasks.query(const TaskQuery(status: StatusFilter.all)), isEmpty);
      expect(tasks.findById(task.id)!.isDeleted, isTrue);
    });
  });

  group('backup', () {
    test('VACUUM INTO snapshot opens as a valid vault with the data',
        () async {
      final task = makeTask(title: 'survives backup');
      final dir = Directory.systemTemp.createTempSync('quadrant-backup-');
      final backupPath = '${dir.path}/snapshot.sqlite3';

      // In-memory databases cannot VACUUM INTO across some platforms, so
      // exercise the real file path: copy into a file vault first.
      final filePath = '${dir.path}/vault.sqlite3';
      final fileDb = QuadrantDatabase.open(filePath);
      SqliteTaskRepository(fileDb).insert(task);
      fileDb.backupTo(backupPath);

      expect(() => fileDb.backupTo(backupPath), throwsA(anything),
          reason: 'refuses to overwrite an existing backup');
      fileDb.close();

      final restored = QuadrantDatabase.open(backupPath);
      final loaded = SqliteTaskRepository(restored).findById(task.id);
      expect(loaded?.title, 'survives backup');
      expect(restored.userVersion, schemaVersion);
      restored.close();
      dir.deleteSync(recursive: true);
    });
  });

  group('recovery and verification', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('quadrant-rec-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('openWithRecovery moves a corrupt file aside and starts fresh',
        () {
      final path = '${dir.path}/vault.sqlite3';
      File(path).writeAsStringSync('this is not a sqlite database at all');

      String? movedTo;
      final database = QuadrantDatabase.openWithRecovery(
        path,
        onCorruptMovedAside: (destination) => movedTo = destination,
      );
      expect(database.userVersion, schemaVersion);
      database.close();

      expect(movedTo, isNotNull);
      expect(File(movedTo!).existsSync(), isTrue,
          reason: 'the damaged file must survive for triage');
      expect(
        File(movedTo!).readAsStringSync(),
        contains('not a sqlite database'),
      );
    });

    test('openWithRecovery leaves healthy vaults untouched', () {
      final path = '${dir.path}/vault.sqlite3';
      final first = QuadrantDatabase.open(path);
      SqliteTaskRepository(first).insert(Task(
        id: EntityId.generate(),
        title: 'keep me',
        notes: '',
        isUrgent: false,
        isImportant: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ));
      first.close();

      final reopened = QuadrantDatabase.openWithRecovery(path);
      final titles = reopened.db
          .select('SELECT title FROM tasks')
          .map((row) => row['title']);
      expect(titles, ['keep me']);
      reopened.close();
    });

    test('openWithRecovery still refuses newer-schema databases', () {
      final path = '${dir.path}/vault.sqlite3';
      final database = QuadrantDatabase.open(path);
      database.db.execute('PRAGMA user_version = ${schemaVersion + 5}');
      database.close();

      expect(
        () => QuadrantDatabase.openWithRecovery(path),
        throwsStateError,
        reason: 'a downgrade is not corruption and must not be recovered',
      );
      expect(File(path).existsSync(), isTrue);
    });

    test('verifySnapshot accepts good snapshots and names bad ones', () {
      final path = '${dir.path}/vault.sqlite3';
      final database = QuadrantDatabase.open(path);
      database.backupTo('${dir.path}/good.sqlite3');
      database.close();

      expect(QuadrantDatabase.verifySnapshot('${dir.path}/good.sqlite3'),
          isNull);
      expect(QuadrantDatabase.verifySnapshot('${dir.path}/missing.sqlite3'),
          contains('does not exist'));

      File('${dir.path}/garbage.sqlite3').writeAsStringSync('garbage');
      expect(
        QuadrantDatabase.verifySnapshot('${dir.path}/garbage.sqlite3'),
        isNotNull,
      );
    });
  });

  group('tag repository', () {
    Tag makeTag(String name) {
      final now = DateTime.utc(2026, 1, 1);
      final tag = Tag(
        id: EntityId.generate(),
        name: name,
        color: '#112233',
        createdAt: now,
        updatedAt: now,
      );
      tags.insert(tag);
      return tag;
    }

    test('enforces unique active names but allows reuse after delete', () {
      final tag = makeTag('home');
      expect(() => makeTag('home'), throwsA(anything));
      tags.update(tag.softDelete(DateTime.utc(2026, 2, 1)));
      expect(makeTag('home').name, 'home');
    });

    test('computes progress over non-deleted tasks', () {
      final tag = makeTag('work');
      final a = makeTask(title: 'a');
      final b = makeTask(title: 'b');
      final c = makeTask(title: 'c');
      for (final task in [a, b, c]) {
        tasks.assignTag(task.id, tag.id);
      }
      tasks.update(a.complete(DateTime.utc(2026, 2, 1)));
      tasks.update(c.softDelete(DateTime.utc(2026, 2, 1)));

      final progress = tags.progressOf(tag.id);
      expect(progress.completed, 1);
      expect(progress.total, 2);
    });

    test('tag filter in task queries and tagIdsOf', () {
      final tag = makeTag('errands');
      final tagged = makeTask(title: 'tagged');
      makeTask(title: 'untagged');
      tasks.assignTag(tagged.id, tag.id);

      expect(
        tasks.query(TaskQuery(tagId: tag.id)).map((t) => t.id),
        [tagged.id],
      );
      expect(tasks.tagIdsOf(tagged.id), [tag.id]);
      expect(tasks.hasTag(tagged.id, tag.id), isTrue);

      tasks.removeTag(tagged.id, tag.id);
      expect(tasks.tagIdsOf(tagged.id), isEmpty);
    });
  });
}
