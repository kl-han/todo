Web Platform Implementation Plan (v2.1)
=======================================

.. note::

   This page is the *plan of record* for the v2.1 web milestone
   (:doc:`/intro/roadmap`). The behavior it schedules is already
   specified under :doc:`/platforms/web/index` and the shared
   product pages; nothing here redefines behavior. It sequences the
   documented-but-unimplemented cross-platform work into vertical
   slices, each landing as its own branch, pull request, and squash
   commit per :doc:`/agents/feature-workflow`.

Why a plan
----------

The web milestone is the first target that reaches across every
platform at once: it introduces shared product behavior (inline
``#``/``!`` entry, grouped task views, boolean filter rules, the
checkbox/row interaction split, quadrant colors, and drag and drop)
that iOS, Linux, and web must all honor identically
(:doc:`/platforms/shared-ui`), plus a browser frontend of the one
shared widget tree. Landing all of that in a single change would break
the "one feature, one branch, one squash commit" rule and hide the
REST-boundary contract behind widget work.

The slices below are ordered so that each one is independently
testable and merges without waiting on a later slice. Pure,
platform-agnostic logic (parsing, the rule language) comes first,
because it is the shared behavior every UI target consumes and it can
be proven by unit tests with no Flutter, browser, or device in the
loop. UI and web-shell slices follow, consuming that logic through the
same REST boundary as every other operation.

Guiding constraints (unchanged)
-------------------------------

* Every operation still crosses the REST boundary; the browser is a
  REST client and never opens SQLite (:doc:`/platforms/web/index`).
* No task rule, parsing rule, or metadata semantic may differ per
  target; divergence stays behind layout breakpoints and input
  conventions (:doc:`/platforms/shared-ui`).
* Filter rules are validated as the user edits and are translated into
  backend/SQLite filtering by the application and backend layers —
  never evaluated in widget logic (:doc:`/product/sorting-filtering`).
* Business rules live in pure packages, not in widgets or REST
  handlers (repository rules in ``AGENTS.md``).

Slices
------

.. list-table::
   :header-rows: 1
   :widths: 4 24 40 32

   * - #
     - Slice
     - Scope
     - Acceptance
   * - 1
     - Inline ``#``/``!`` entry engine
     - Pure ``quadrant_input`` package: detect the active inline token
       under the caret, produce ``#`` tag suggestions and the four
       ``!`` flag completions, map a confirmed completion to an
       importance/urgency change, and honor "``!`` before a space is
       literal" and "space terminates a tag name"
       (:doc:`/product/task-behavior`, :doc:`/product/tag-behavior`).
     - Unit tests cover caret cases, prefix narrowing, new-vs-existing
       tag, and the literal-``!`` rule. No Flutter dependency.
   * - 2
     - Filter-rule expression language
     - Pure ``quadrant_query`` package: lexer, parser, AST, validator,
       and a reference in-memory evaluator for the boolean rule
       language with the documented precedence
       (:doc:`/product/sorting-filtering`).
     - Unit tests cover the precedence table, parenthesization,
       validation errors (unsaveable/unappliable rules), and evaluation
       against task facts. Reference semantics the SQL translation must
       match.
   * - 3
     - Rule → backend filtering
     - Translate a validated rule into backend/SQLite filtering in the
       application and store layers; extend ``api/openapi.yaml`` and the
       conformance suite so both backends filter identically; advertise
       a ``filter-rules`` capability.
     - Conformance passes on embedded **and** standalone backends;
       results match the slice-2 reference evaluator.
   * - 4
     - Grouped task views
     - Group the Tasks list by tag, by importance/urgency, or by both,
       as presentation over the same ordered result set, combining with
       status filter and rules; tag groups show progress
       (:doc:`/product/sorting-filtering`).
     - Widget/acceptance tests: grouping preserves
       ``matrix_modified_asc`` within groups and composes with filters.
   * - 5
     - Row interaction split + inline entry UI
     - Split ``TaskTile`` so the checkbox toggles completion and the
       rest of the row opens editing by default (setting restores
       toggle-on-activation); wire the slice-1 engine into quick-add and
       the editor with keyboard/pointer/touch confirmation
       (:doc:`/platforms/web/interaction-model`,
       :doc:`/reference/keyboard-reference`).
     - Acceptance tests on the shared tree for checkbox vs body
       activation and autocomplete confirmation across input modes.
   * - 6
     - Quadrant colors + drag and drop
     - Quadrant color treatment and Matrix drag-and-drop moves that
       update urgency/importance through the REST client, with a
       visible pending-drop state and a keyboard-accessible
       move-to-quadrant alternative (:doc:`/product/quadrant-behavior`,
       :doc:`/platforms/web/interaction-model`,
       :doc:`/platforms/web/accessibility`).
     - Accessibility never depends on drag alone; move maps to a flag
       change the editor could also make.
   * - 7
     - Editing / Rules tab + responsive shell
     - Add the Editing / Rules tab (create, edit, validate, remove
       rules) and the responsive breakpoints
       (:doc:`/platforms/web/responsive-shell`); reuse the existing
       600lp matrix-stack breakpoint; preserve per-tab state.
     - Responsive tests at both breakpoints; no state or option
       exclusive to the wide layout.
   * - 8
     - Web target bring-up
     - Enable the Flutter web target of the shared widget tree over the
       REST client, backend connectivity by base URL, and the web test
       plan (:doc:`/platforms/web/backend-connectivity`,
       :doc:`/testing/index`).
     - Web build runs against a standalone backend; REST-boundary and
       accessibility tests pass.

Cross-platform decisions this plan surfaces
-------------------------------------------

The open cross-cutting questions in :doc:`/todo` are resolved *inside*
the slices that first depend on them, not up front:

* **Third tab across platforms** — decided with slice 7 (whether iOS
  and Linux adopt Editing / Rules in place of the Tags tab).
* **Tag names with spaces** — decided with slice 1/3, since inline
  ``#`` entry requires space-free, addressable tag names.
* **Touch drag versus move controls** — decided with slice 6; the
  accessible fallback ships regardless.
* **Browser auth-state, CORS, version numbering** — belong to the v3.0
  remote sync/auth milestone
  (:doc:`/platforms/web/sync-auth-preparation`) and are out of scope
  here.

Sequencing
----------

Slices 1 and 2 are pure logic and land first. Slice 3 wires the rule
language across the REST boundary. Slices 4–7 build the shared-UI
behavior on top, and slice 8 brings up the browser target. This change
opens the milestone with slices 1 and 2 (the ``quadrant_input`` and
``quadrant_query`` packages); the remaining slices follow as their own
pull requests.
