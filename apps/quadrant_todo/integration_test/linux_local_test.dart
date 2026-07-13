import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quadrant_todo/bootstrap/local_bootstrap.dart';
import 'package:quadrant_todo/presentation/app.dart';
import 'package:quadrant_todo/state/app_state.dart';

/// Linux acceptance test against the REAL embedded backend isolate and a
/// real on-disk vault. Run on a Linux desktop session:
///
///   flutter test integration_test/linux_local_test.dart -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('local mode end-to-end: boot, create, toggle, persist',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('quadrant-it-');
    final dbPath = '${dir.path}/default.sqlite3';

    final connection = await bootstrapLocalBackend(databasePath: dbPath);
    final state = AppState(connection);
    await tester.pumpWidget(QuadrantTodoApp(state: state));
    await tester.pumpAndSettle();

    // Create through the UI.
    await tester.enterText(
        find.byKey(const ValueKey('add-task-field')), 'integration task');
    await tester.tap(find.byKey(const ValueKey('add-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('integration task'), findsOneWidget);

    // Toggle completion (Enter-equivalent activation).
    await tester.tap(find.text('integration task'));
    await tester.pumpAndSettle();

    // Restart the backend — data must have been durably committed.
    final restarted = await connection.restart!.call();
    final tasks = await restarted.client.listTasks(status: 'completed');
    expect(tasks.map((t) => t.title), contains('integration task'));

    await restarted.shutdown?.call();
    dir.deleteSync(recursive: true);
  });
}
