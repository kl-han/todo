import 'package:flutter/material.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

import '../bootstrap/backend_selector.dart';
import '../state/app_state.dart';
import 'home_shell.dart';

/// Application root. All data flows through [AppState]'s REST client;
/// this widget tree owns no storage and no business rules.
class QuadrantTodoApp extends StatelessWidget {
  QuadrantTodoApp({
    super.key,
    required this.state,
    SettingsStore? settingsStore,
    CredentialStore? credentialStore,
  })  : settingsStore = settingsStore ?? defaultSettingsStore(),
        credentialStore = credentialStore ?? defaultCredentialStore();

  final AppState state;
  final SettingsStore settingsStore;
  final CredentialStore credentialStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quadrant Todo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: HomeShell(
        state: state,
        settingsStore: settingsStore,
        credentialStore: credentialStore,
      ),
    );
  }
}
