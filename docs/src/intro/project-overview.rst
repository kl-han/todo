Project Overview
================

Quadrant Todo is a personal task manager built around the Eisenhower
matrix: every open task lives in one of four quadrants derived from its
urgency and importance flags. It runs on iOS and on Linux (Sway/Wayland)
from a single Flutter codebase.

The defining architectural property is a **REST boundary for every
application operation**:

* **Local mode** — Flutter UI → loopback HTTP → embedded backend isolate →
  local SQLite.
* **Remote mode** — Flutter UI → HTTPS → standalone backend → server-side
  SQLite vault.

The same API routes, application services, validation, and repository
interfaces serve both modes; the conformance suite
(:doc:`/testing/backend-conformance`) proves it on every change.

Switching backends switches the source of truth. There is no
synchronization subsystem before v1.0
(:doc:`/decisions/adr-0005-no-sync-before-v1`).
