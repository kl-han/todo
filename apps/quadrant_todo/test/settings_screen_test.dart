import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';
import 'package:quadrant_todo/presentation/app.dart';
import 'package:quadrant_todo/state/app_state.dart';

import 'fake_backend.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('quadrant-ui-set-'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pumpApp(WidgetTester tester, FakeBackend backend) async {
    final state = AppState(backend.connection());
    await tester.pumpWidget(QuadrantTodoApp(
      state: state,
      settingsStore: SettingsStore('${dir.path}/backend.json'),
      credentialStore: InMemoryCredentialStore(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('settings opens with local mode selected by default',
      (tester) async {
    await pumpApp(tester, FakeBackend());

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Backend settings'), findsOneWidget);
    expect(find.byKey(const ValueKey('remote-url')), findsNothing,
        reason: 'remote fields hidden while local mode is selected');
  });

  testWidgets('choosing remote reveals URL/vault/token and test button',
      (tester) async {
    await pumpApp(tester, FakeBackend());
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mode-remote')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('remote-url')), findsOneWidget);
    expect(find.byKey(const ValueKey('remote-vault')), findsOneWidget);
    expect(find.byKey(const ValueKey('remote-token')), findsOneWidget);
    expect(find.byKey(const ValueKey('test-connection')), findsOneWidget);
  });

  testWidgets('switching modes asks for explicit confirmation',
      (tester) async {
    await pumpApp(tester, FakeBackend());
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mode-remote')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('remote-url')), 'https://todo.example');
    await tester.tap(find.byKey(const ValueKey('settings-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('switch-confirm')), findsOneWidget);
    expect(find.textContaining('nothing is merged', findRichText: true),
        findsOneWidget);

    // Cancel keeps the stored settings untouched (local mode).
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      SettingsStore('${dir.path}/backend.json').load().mode,
      BackendMode.local,
    );
  });
}
