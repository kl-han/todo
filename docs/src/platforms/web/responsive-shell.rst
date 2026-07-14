Responsive Shell
================

One shell, the same three primary tabs everywhere:

* **Matrix**
* **Tasks**
* **Editing / Rules**

Tab state is preserved when switching tabs: scroll position, the active
grouping, an in-progress (but not yet submitted) editor, and the current
filter selection survive a round trip through another tab.

On large screens the web UI optimizes for scanning and repeated task
management; on small screens it preserves the same task operations with
touch-friendly controls and readable density. The layout changes; the
underlying task model does not. Layout divergence stays where it lives
on every platform — behind breakpoints in the shared widget tree
(:doc:`/platforms/shared-ui`), reusing the existing 600lp matrix-stack
breakpoint rather than inventing a web-only one.

Large-screen layout
-------------------

Desktop browsers and landscape tablets:

* a persistent tab/navigation affordance that is always visible — no
  hamburger-only navigation;
* the Matrix as a true 2×2 grid with all four quadrants on screen at
  once;
* the Tasks and Editing / Rules views may use wider panes or
  side-by-side layouts (for example rule list beside rule editor), as
  long as no state or option is exclusive to the wide layout.

Small-screen layout
-------------------

Narrow mobile browsers and portrait tablets:

* bottom or otherwise compact navigation reachable with one thumb;
* the Matrix collapses into stacked (or swipe-friendly) quadrant
  sections — the same stacking rule the shared tree already applies
  below 600lp;
* editing surfaces fit the viewport without horizontal scrolling,
  including the rule editor's multiline input.

Grouping controls
-----------------

The Tasks tab's grouping and filter-rule controls
(:doc:`/product/sorting-filtering`) follow the same split:

* **Large screens** — visible controls or segmented selectors, so the
  active grouping and rule are readable at a glance.
* **Small screens** — the same options collapse into compact menus or
  sheets; nothing is removed, only folded away.

The group-by-tag view of the Tasks tab provides the tag-progress
overview that the dedicated Tags tab provides on iOS and Linux today;
whether those platforms adopt the Editing / Rules tab in place of Tags
is an open cross-platform question tracked in :doc:`/todo`.
