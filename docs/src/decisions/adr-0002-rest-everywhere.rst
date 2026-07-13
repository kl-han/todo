ADR-0002: REST Boundary for Every Operation
===========================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

The app must support two data locations — on-device and self-hosted
server — without maintaining two behavioral implementations. A direct
in-process persistence path for local mode plus an HTTP path for remote
mode would duplicate every rule and guarantee divergence.

Decision
--------

Every application operation crosses a REST boundary, in both modes. Local
mode runs the same handler stack behind a loopback HTTP server in a
dedicated backend isolate; remote mode reaches a standalone server over
HTTPS. ``api/openapi.yaml`` is the single normative contract, and one
conformance suite must pass against both backends.

Consequences
------------

* Exactly one implementation of every route, service, and validation.
* Local/remote behavioral equivalence is testable and continuously
  tested — the conformance suite is the project's most important test
  artifact.
* Cost: local operations pay HTTP serialization overhead on loopback.
  Accepted; performance work is deferred until real post-v1.0 usage data
  exists.
* The UI cannot take shortcuts into storage even accidentally: the store
  packages are not dependencies of the presentation layer.
