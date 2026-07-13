import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrant_todo/presentation/app.dart';
import 'package:quadrant_todo/state/app_state.dart';

import 'fake_backend.dart';

Future<AppState> _pumpApp(WidgetTester tester, FakeBackend backend) async {
  final state = AppState(backend.connection());
  await tester.pumpWidget(QuadrantTodoApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('matrix tab shows four quadrants with counts', (tester) async {
    final backend = FakeBackend()
      ..addTask('do first', urgent: true, important: true)
      ..addTask('later');

    await _pumpApp(tester, backend);

    expect(find.textContaining('Q1 — Urgent · Important (1)'), findsOneWidget);
    expect(find.textContaining('Q4 — Neither (1)'), findsOneWidget);
    expect(find.text('do first'), findsOneWidget);
  });

  testWidgets('adding a task through the field creates it', (tester) async {
    final backend = FakeBackend();
    await _pumpApp(tester, backend);

    await tester.enterText(
        find.byKey(const ValueKey('add-task-field')), 'new task');
    await tester.tap(find.byKey(const ValueKey('add-task-button')));
    await tester.pumpAndSettle();

    expect(backend.tasks.single['title'], 'new task');
    expect(find.text('new task'), findsOneWidget);
  });

  testWidgets('tapping a task toggles completion via PATCH', (tester) async {
    final backend = FakeBackend()..addTask('toggle me');
    await _pumpApp(tester, backend);

    await tester.tap(find.text('toggle me'));
    await tester.pumpAndSettle();

    expect(backend.tasks.single['status'], 'completed');
  });

  testWidgets('Alt+2 and Alt+3 switch tabs', (tester) async {
    final backend = FakeBackend()..addTask('a task');
    await _pumpApp(tester, backend);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget); // Tasks tab filter

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-tag-field')), findsOneWidget);
  });

  testWidgets('typing h/j/k/l into a text field does not move focus',
      (tester) async {
    final backend = FakeBackend();
    await _pumpApp(tester, backend);

    await tester.tap(find.byKey(const ValueKey('add-task-field')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('add-task-field')), 'hjkl');
    await tester.pump();

    // The letters land in the field instead of triggering focus movement.
    expect(find.text('hjkl'), findsOneWidget);
  });

  testWidgets('unreachable backend shows the error banner with retry',
      (tester) async {
    final backend = FakeBackend()..unreachable = true;
    await _pumpApp(tester, backend);

    expect(find.byKey(const ValueKey('error-banner')), findsOneWidget);
    expect(find.text('Backend unreachable.'), findsOneWidget);

    backend.unreachable = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('error-banner')), findsNothing);
  });

  testWidgets('tags tab lists progress and opens the tag task view',
      (tester) async {
    final backend = FakeBackend();
    backend.tags.add({
      'id': 'tag-1',
      'name': 'home',
      'color': '#112233',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'version': 1,
      'progress': {'completed': 1, 'total': 3},
    });
    await _pumpApp(tester, backend);

    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    expect(find.text('Tag: home'), findsOneWidget);
  });
}
