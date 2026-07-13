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

  testWidgets('swipe-to-delete shows Undo and restore brings the task back',
      (tester) async {
    final backend = FakeBackend();
    final task = backend.addTask('swipe me');
    await pumpApp(tester, backend);

    await tester.drag(
      find.byKey(ValueKey('dismiss-${task['id']}')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(backend.tasks.single['deleted_at'], isNotNull);
    expect(find.byKey(const ValueKey('undo-snackbar')), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(backend.tasks.single['deleted_at'], isNull);
    expect(find.text('swipe me'), findsOneWidget);
  });

  testWidgets('editor delete also offers Undo', (tester) async {
    final backend = FakeBackend();
    final task = backend.addTask('editor delete');
    await pumpApp(tester, backend);

    await tester.tap(find.byKey(ValueKey('edit-${task['id']}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('editor-delete')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('undo-snackbar')), findsOneWidget);
  });

  testWidgets('quadrant filter narrows the flat task list', (tester) async {
    final backend = FakeBackend()
      ..addTask('urgent important', urgent: true, important: true)
      ..addTask('plain');
    await pumpApp(tester, backend);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('urgent important'), findsOneWidget);
    expect(find.text('plain'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quadrant-filter-1')));
    await tester.pumpAndSettle();
    expect(find.text('urgent important'), findsOneWidget);
    expect(find.text('plain'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('quadrant-filter-all')));
    await tester.pumpAndSettle();
    expect(find.text('plain'), findsOneWidget);
  });
}
