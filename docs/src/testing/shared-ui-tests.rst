Shared UI Tests
===============

.. versionadded:: 0.3

Widget tests exercise the shared presentation layer against
``FakeBackend`` (``apps/quadrant_todo/test/fake_backend.dart``) — a tiny
in-memory implementation of the v1 wire contract behind ``MockClient``,
so no sockets and no timing flakes.

The fake is intentionally dumb: contract fidelity is proven by the
conformance suite against real backends; widget tests only need
deterministic JSON. If the wire shape changes, the OpenAPI change, the
conformance suite, and the fake all move in the same pull request.

Covered behaviors: quadrant grouping and counts, quick-add round trip,
toggle-on-activation, tab switching (pointer and ``Alt+number``),
text-focus shortcut suppression, tag progress display and drill-down, and
the explicit offline banner with retry.
