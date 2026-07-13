Linux Tests
===========

.. versionadded:: 0.3

Three layers, run on a Linux desktop session with the Flutter SDK:

1. **Widget tests** (``apps/quadrant_todo/test``): tab switching via
   ``Alt+1/2/3``, quadrant rendering, quick-add, completion toggling,
   text-focus shortcut suppression, and the offline banner — all against a
   deterministic in-memory fake of the v1 contract.
2. **Integration test**
   (``integration_test/linux_local_test.dart``): the real embedded backend
   isolate with a real on-disk vault — boot, create, toggle, restart the
   backend, and verify durability. Run with
   ``flutter test integration_test -d linux``.
3. **Manual Sway checklist** (v0.3 exit): tiled/floating resize behavior,
   workspace switching, close-and-reopen with data intact, full keyboard
   session without touching the pointer.

These tests cannot run in headless CI without a display server; they are
the developer-workstation part of the quality gate, recorded per release
in the release checklist.
