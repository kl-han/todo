Keyboard Navigation
===================

.. versionadded:: 0.3

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Keys
     - Behavior
   * - ``Alt+1`` / ``Alt+2`` / ``Alt+3``
     - Switch to Matrix / Tasks / Tags tab
   * - ``h`` ``j`` ``k`` ``l``
     - Move focus left / down / up / right between task tiles
   * - ``Enter``
     - Toggle completion of the focused task
   * - ``Tab`` / ``Shift+Tab``
     - Standard focus traversal (always available)

Text-focus suppression
----------------------

Single-letter shortcuts (``h/j/k/l``) are disabled whenever an editable
text widget holds focus, so titles containing those letters can be typed
normally. ``Alt+number`` chords remain active. Implementation:
``MoveFocusAction.isEnabled`` checks ``textInputHasFocus()``
(``apps/quadrant_todo/lib/platform/keyboard.dart``).

``Enter`` inside the quick-add field submits the new task rather than
toggling anything — the focused widget wins.
