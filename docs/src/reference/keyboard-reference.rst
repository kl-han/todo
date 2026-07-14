Keyboard Reference
==================

.. list-table::
   :header-rows: 1
   :widths: 25 45 30

   * - Keys
     - Action
     - Since
   * - ``Alt+1``
     - Matrix tab
     - 0.3
   * - ``Alt+2``
     - Tasks tab
     - 0.3
   * - ``Alt+3``
     - Tags tab
     - 0.3
   * - ``h`` / ``j`` / ``k`` / ``l``
     - Focus left / down / up / right (outside text input)
     - 0.3
   * - ``Enter``
     - Toggle focused task's completion; submit in text fields
     - 0.3
   * - ``Tab`` / ``Shift+Tab``
     - Focus traversal
     - 0.3

iOS relies on touch; hardware-keyboard support inherits this table.
The web platform (:doc:`/platforms/web/index`) inherits it too —
desktop browsers get the same chords and traversal, touch browsers
follow iOS conventions.

Inline autocomplete (planned)
-----------------------------

.. versionadded:: 2.1

Navigation inside the ``#`` / ``!`` suggestion list while editing a
title (:doc:`/product/task-behavior`):

.. list-table::
   :header-rows: 1
   :widths: 25 45 30

   * - Keys
     - Action
     - Since
   * - ``Down`` / ``Up``
     - Move through suggestions
     - 2.1
   * - ``Ctrl+N`` / ``Ctrl+P``
     - Move through suggestions (Linux-parity alternative)
     - 2.1
   * - ``Enter``
     - Confirm the highlighted suggestion
     - 2.1
   * - ``Esc``
     - Dismiss suggestions, keep the typed text
     - 2.1
   * - ``Space``
     - End inline tag entry (creates the tag when the name is new)
     - 2.1
