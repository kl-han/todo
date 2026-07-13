import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 1, 1);
final t1 = DateTime.utc(2026, 1, 2);

Task _task({bool isUrgent = false, bool isImportant = false}) => Task(
      id: EntityId.generate(),
      title: 'title',
      notes: '',
      isUrgent: isUrgent,
      isImportant: isImportant,
      createdAt: t0,
      updatedAt: t0,
    );

void main() {
  group('Quadrant.derive', () {
    test('maps the four flag combinations', () {
      expect(
        Quadrant.derive(isUrgent: true, isImportant: true),
        Quadrant.q1,
      );
      expect(
        Quadrant.derive(isUrgent: false, isImportant: true),
        Quadrant.q2,
      );
      expect(
        Quadrant.derive(isUrgent: true, isImportant: false),
        Quadrant.q3,
      );
      expect(
        Quadrant.derive(isUrgent: false, isImportant: false),
        Quadrant.q4,
      );
    });

    test('is derived from task flags, never stored', () {
      expect(_task(isUrgent: true, isImportant: true).quadrant, Quadrant.q1);
      expect(_task().quadrant, Quadrant.q4);
    });
  });

  group('Task transitions', () {
    test('complete sets completed_at and increments version', () {
      final task = _task();
      final completed = task.complete(t1);
      expect(completed.status, TaskStatus.completed);
      expect(completed.completedAt, t1);
      expect(completed.version, task.version + 1);
      expect(completed.updatedAt, t1);
    });

    test('reopen clears completed_at and increments version', () {
      final completed = _task().complete(t0);
      final reopened = completed.reopen(t1);
      expect(reopened.status, TaskStatus.open);
      expect(reopened.completedAt, isNull);
      expect(reopened.version, completed.version + 1);
    });

    test('soft delete and restore round-trip', () {
      final task = _task();
      final deleted = task.softDelete(t1);
      expect(deleted.isDeleted, isTrue);
      final restored = deleted.restore(t1);
      expect(restored.isDeleted, isFalse);
      expect(restored.version, task.version + 2);
    });

    test('edit changes classification and bumps version', () {
      final edited = _task().edit(t1, isUrgent: true, title: 'new');
      expect(edited.quadrant, Quadrant.q3);
      expect(edited.title, 'new');
      expect(edited.version, 2);
    });
  });

  group('validation rules', () {
    test('task title is trimmed and must be non-empty', () {
      expect(validateTaskTitle('  x  '), 'x');
      expect(() => validateTaskTitle('   '), throwsA(isA<DomainValidationError>()));
      expect(
        () => validateTaskTitle('a' * (maxTitleLength + 1)),
        throwsA(isA<DomainValidationError>()),
      );
    });

    test('tag name and color rules', () {
      expect(validateTagName(' home '), 'home');
      expect(validateTagColor('#A1b2C3'), '#a1b2c3');
      expect(
        () => validateTagColor('red'),
        throwsA(isA<DomainValidationError>()),
      );
    });
  });

  group('EntityId', () {
    test('generates valid v4 UUIDs', () {
      final id = EntityId.generate();
      expect(EntityId.isValid(id), isTrue);
      expect(id[14], '4');
      expect(EntityId.generate(), isNot(id));
    });
  });
}
