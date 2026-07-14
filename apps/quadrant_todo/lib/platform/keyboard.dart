import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Linux keyboard conventions (see docs/src/platforms/linux/):
///
/// * ``Alt+1/2/3`` switch tabs.
/// * ``h/j/k/l`` move focus left/down/up/right between task tiles.
/// * ``Enter`` toggles completion of the focused task.
///
/// All single-letter shortcuts are suppressed while a text field has
/// focus, so typing "hjkl" into a title works as expected.
class SwitchTabIntent extends Intent {
  const SwitchTabIntent(this.index);

  final int index;
}

class MoveFocusIntent extends Intent {
  const MoveFocusIntent(this.direction);

  final TraversalDirection direction;
}

/// True when the primary focus is inside an editable text widget; letter
/// shortcuts must not fire then.
///
/// A focused text field may attach its node either at the inner
/// [EditableText] or at the surrounding [TextField], so both ancestor
/// checks are needed. Only ancestors count: scanning descendants would
/// make the shell's own autofocused node (whose subtree contains the
/// always-present quick-add field) look like text input and suppress
/// h/j/k/l before the user focuses anything.
bool textInputHasFocus() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.widget is EditableText ||
      context.findAncestorStateOfType<EditableTextState>() != null ||
      context.findAncestorWidgetOfExactType<TextField>() != null;
}

/// App-level shortcut map. Vim-style keys are wrapped so they only apply
/// outside text input.
Map<ShortcutActivator, Intent> appShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.digit1, alt: true):
      const SwitchTabIntent(0),
  const SingleActivator(LogicalKeyboardKey.digit2, alt: true):
      const SwitchTabIntent(1),
  const SingleActivator(LogicalKeyboardKey.digit3, alt: true):
      const SwitchTabIntent(2),
  const SingleActivator(LogicalKeyboardKey.keyH): const MoveFocusIntent(
    TraversalDirection.left,
  ),
  const SingleActivator(LogicalKeyboardKey.keyJ): const MoveFocusIntent(
    TraversalDirection.down,
  ),
  const SingleActivator(LogicalKeyboardKey.keyK): const MoveFocusIntent(
    TraversalDirection.up,
  ),
  const SingleActivator(LogicalKeyboardKey.keyL): const MoveFocusIntent(
    TraversalDirection.right,
  ),
};

/// Action for [MoveFocusIntent] that respects text-input suppression.
class MoveFocusAction extends Action<MoveFocusIntent> {
  @override
  bool isEnabled(MoveFocusIntent intent) => !textInputHasFocus();

  @override
  Object? invoke(MoveFocusIntent intent) {
    FocusManager.instance.primaryFocus?.focusInDirection(intent.direction);
    return null;
  }
}
