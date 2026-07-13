import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'bootstrap/backend_selector.dart';
import 'bootstrap/remote_bootstrap.dart';
import 'presentation/app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final connection = await bootstrapFromSettings();
    runApp(QuadrantTodoApp(state: AppState(connection)));
  } on IncompatibleBackendException catch (error) {
    // Retrying cannot fix a version mismatch; say so instead of looping.
    runApp(_FatalErrorApp(message: error.toString()));
  }
}

class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Cannot use the configured backend:\n\n$message\n\n'
              'Update the server or edit '
              '~/.config/quadrant-todo/backend.json.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
