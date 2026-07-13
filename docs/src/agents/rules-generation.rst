Rules Generation
================

How ``AGENTS.md`` files are written and kept useful:

* **Root rules are invariants**, not advice: each line is checkable in
  review ("The UI communicates with backends only through the REST
  client"). If a rule cannot be violated detectably, it does not belong.
* **Nested files hold only subtree-specific requirements** —
  ``apps/quadrant_todo/AGENTS.md`` talks about widgets and platforms,
  ``packages/quadrant_api_server/AGENTS.md`` about handlers, never
  repeating the root.
* **Small beats complete**: an agent reads rules on every task; a page
  that scrolls gets skimmed. Details belong in docs pages the rules link
  to.
* **A recurring review problem becomes a rule** — after the second time a
  change places business logic in a handler, the prohibition is written
  down.
* **Rules follow decisions**: when an ADR lands, its enforceable
  consequences are distilled into the relevant ``AGENTS.md`` in the same
  pull request.
