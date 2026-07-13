import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrant_todo/presentation/app.dart';
import 'package:quadrant_todo/state/app_state.dart';

import 'fake_backend.dart';

void main() {
  Future<AppState> pumpApp(WidgetTester tester, FakeBackend backend) async {
    final state = AppState(backend.connection());
    await tester.pumpWidget(QuadrantTodoApp(state: state));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('narrow layout stacks quadrants into one column',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3); // iPhone 13 Pro
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final backend = FakeBackend()..addTask('phone task');
    await pumpApp(tester, backend);

    expect(find.byKey(const ValueKey('matrix-narrow')), findsOneWidget);
    expect(find.byKey(const ValueKey('matrix-grid')), findsNothing);
  });

  testWidgets('wide layout keeps the 2x2 grid', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final backend = FakeBackend()..addTask('desktop task');
    await pumpApp(tester, backend);

    expect(find.byKey(const ValueKey('matrix-grid')), findsOneWidget);
  });

  testWidgets('editor saves title, notes, and classification',
      (tester) async {
    final backend = FakeBackend();
    final task = backend.addTask('before');
    await pumpApp(tester, backend);

    await tester.tap(find.byKey(ValueKey('edit-${task['id']}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-editor')), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('editor-title')), 'after');
    await tester.tap(find.byKey(const ValueKey('editor-urgent')));
    await tester.tap(find.byKey(const ValueKey('editor-save')));
    await tester.pumpAndSettle();

    // The fake echoes PATCHes into its task map.
    expect(backend.lastPatch?['title'], 'after');
    expect(backend.lastPatch?['is_urgent'], true);
  });

  testWidgets('editor delete removes the task from the list',
      (tester) async {
    final backend = FakeBackend();
    final task = backend.addTask('doomed');
    await pumpApp(tester, backend);

    await tester.tap(find.byKey(ValueKey('edit-${task['id']}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-delete')));
    await tester.pumpAndSettle();

    expect(find.text('doomed'), findsNothing);
    expect(backend.tasks.single['deleted_at'], isNotNull);
  });
}
