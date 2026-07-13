import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'home_shell.dart';

/// Application root. All data flows through [AppState]'s REST client;
/// this widget tree owns no storage and no business rules.
class QuadrantTodoApp extends StatelessWidget {
  const QuadrantTodoApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quadrant Todo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: HomeShell(state: state),
    );
  }
}
