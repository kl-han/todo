Web Tests
=========

.. versionadded:: 2.1

Planned test scope for the web platform (:doc:`/platforms/web/index`).
Web tests verify browser behavior; product logic stays in shared tests —
the same task-handling rules must pass whether the frontend is Linux,
mobile, or web.

* **Shared UI tests** — web behavior lands in the shared widget tests
  (:doc:`shared-ui-tests`) wherever possible, against ``FakeBackend``.
* **Responsive layout tests** — large-screen (2×2 matrix, persistent
  navigation) and small-screen (stacked quadrants, compact navigation)
  renderings of the same state, keyed to the shared breakpoints.
* **Autocomplete tests** — ``#`` and ``!`` entry: suggestion filtering,
  Enter/click/tap confirmation, arrow and ``Ctrl+N``/``Ctrl+P``
  navigation, new-tag-by-space, no spaces in tag names, literal
  ``!``-then-space, identical behavior in create and edit flows.
* **Drag/drop tests** — or equivalent metadata-change tests: a drop on
  a quadrant issues exactly the urgency/importance update, and the
  keyboard/move fallback produces the identical request.
* **Rule tests** — parser and validation: precedence, parentheses,
  comparisons, rejection of invalid expressions, and that invalid rules
  cannot be saved or applied.
* **REST-boundary tests** — web code imports no store internals; the
  existing import-boundary checks extend to the web target.
* **Accessibility tests** — keyboard-only and non-pointer paths: tab
  reachability, autocomplete without a pointer, move-to-quadrant
  without drag, separate checkbox/edit semantics on task rows.

Documentation changes that accompany web work run the docs build as
part of the gate:

.. code-block:: shell

   sphinx-build -W --keep-going -b html docs/src docs/build/html
