import 'package:flutter/material.dart';
import 'package:quadrant_api_client/quadrant_api_client.dart';

import '../state/app_state.dart';

/// Soft deletion is undoable: every delete surfaces a snackbar whose
/// Undo action calls the restore endpoint, bringing back exactly the
/// task that was deleted — tags included.
void showUndoDeleteSnackBar(
  ScaffoldMessengerState messenger,
  AppState state,
  TaskDto task,
) {
  messenger.showSnackBar(
    SnackBar(
      key: const ValueKey('undo-snackbar'),
      content: Text('Deleted "${task.title}"'),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => state.restoreTask(task.id),
      ),
    ),
  );
}
