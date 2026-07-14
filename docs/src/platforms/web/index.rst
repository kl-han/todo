Web
===

The web client is a supported frontend target for Quadrant Todo. It uses
the same product behavior as the mobile and Linux clients and reaches
backends only through the typed REST client.

Runtime model
-------------

The browser is an HTTP client. It does not open SQLite files, import
store internals, or implement backend business rules. Local, standalone,
and future remote backends are selected as HTTP sources of truth according
to the documented backend mode.

Responsive layout
-----------------

The web shell supports both large and small screens:

* Large screens prioritize scanning and repeated task management. The
  Matrix view uses a 2×2 layout; task grouping and rule editing may use
  wider controls or adjacent panes.
* Small screens keep the same Matrix, Tasks, and Editing / Rules tabs in
  a compact layout. Controls may collapse into menus or sheets, but task
  creation, editing, tag entry, urgency/importance changes, filtering,
  and completion behave the same way.

Input behavior
--------------

Desktop web supports mouse and keyboard interaction. Touch web supports
tap-first interaction. Autocomplete suggestions in title editing can be
confirmed with the keyboard or by clicking/tapping the suggestion.

Drag and drop may be used to move tasks between Matrix quadrants. The
operation updates urgency and importance flags through the REST client.
Accessible alternatives must expose the same metadata change without
requiring pointer drag.

Remote readiness
----------------

The web platform is prepared for the v3.0 remote phases: remote sync
followed by remote authentication. Until those behaviors are specified and
implemented, the web client must not introduce hidden synchronization
between local and remote datasets.
