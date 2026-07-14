General Todo
============

This page captures cross-cutting documentation todos that do not belong
to a single component page.

Shared behavior
---------------

- [ ] The web, Linux, and mobile clients must describe the same product
  behavior. Platform pages may document different input conventions, but
  task creation, task editing, tag assignment, urgency/importance
  changes, completion, filtering, and grouping should resolve to the same
  domain operations.

Autocomplete ownership
----------------------

- [ ] Autocomplete semantics should have one product definition. Platform
  pages may reference the keyboard or touch mechanics, but the meaning of
  ``#`` tag entry and ``!`` importance/urgency entry belongs to task
  editing behavior.

Filtering ownership
-------------------

- [ ] Boolean filtering should be documented as product behavior and
  implemented outside widgets. SQLite translation details belong to the
  application and backend layers; user-facing docs should describe the
  rule language and the observable filtering result.

Remote v3.0 boundaries
----------------------

- [ ] v3.0 documentation must clarify the relationship between local
  backend mode, remote sync, and remote authentication. Remote sync and
  remote auth should be documented before implementation and must not
  imply hidden synchronization while local and remote datasets remain
  separate sources of truth.
