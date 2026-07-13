Goals and Non-Goals
===================

Goals
-----

* One behavioral contract (``api/openapi.yaml``) served identically by the
  embedded and standalone backends.
* A local mode that works fully offline and a remote mode that is honestly
  online-only.
* Deterministic task ordering and derived quadrants — no hidden state.
* Specification-first development: behavior, contract, and tests precede
  implementation.
* Documentation updated as part of every feature, verified by a
  warning-free Sphinx build.

Non-goals before v1.0
---------------------

* Synchronization, import/export between local and remote datasets, or any
  automatic data copying between backends.
* Scheduled background work on iOS; the embedded backend lives and dies
  with the app process.
* Performance benchmarking and optimization; measurement starts after v1.0
  produces real usage data.
* Multi-user collaboration; vaults are personal.
