Evidence and Review
===================

Claims about a change must come with evidence, in the pull request:

* **Tests are the primary evidence** — name the suites that ran and their
  results. "Conformance: N assertions × both harnesses, green" is the
  sentence that matters most in this repository.
* **What was not verified is stated plainly**: Flutter widget tests need
  an SDK, device checklists need hardware. Unverified work is labeled
  deferred, never implied done.
* **Docs are part of the diff** — a behavior change without its product/
  API/platform page update is incomplete, and the ``-W`` docs build is
  part of the gate.
* **Failures are reported verbatim**: if a gate fails, the PR says so
  with the output; it is not marked ready.

Review checks, in priority order:

1. Boundary violations (:doc:`/architecture/conceptual-layers`).
2. Contract drift: OpenAPI vs. handlers vs. conformance suite.
3. Behavior missing from the conformance suite.
4. Rules of ``AGENTS.md`` (e.g. no sync before v1.0, problems not
   invented envelopes).
5. Documentation currency.
