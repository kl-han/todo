Agent Working Model
===================

Coding agents (and humans) work this repository the same way:

* **Rules** live in ``AGENTS.md`` files — small, durable constraints an
  agent must always honor (root file plus subtree files for the app, the
  API server, the server, and the docs). Rules say *what must hold*.
* **Skills** live in ``.agents/skills/`` — repeatable multi-step
  procedures (implement a vertical slice, update the REST contract, add a
  migration, verify conformance, prepare a release). Skills say *how to
  do a job*.
* **Documentation** is the source of truth for design: an agent that
  wants to know how something works reads ``docs/src``, not the git log.

Division of labor:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Artifact
     - Holds
   * - ``AGENTS.md``
     - Invariants: boundaries, prohibited dependencies, gates
   * - ``.agents/skills/``
     - Procedures: ordered steps with references and checklists
   * - ``docs/src``
     - Design, behavior, and rationale (this tree)
   * - ADRs
     - Decisions with consequences, one page each

One feature per branch; the auto-squash-merge workflow lands it as a
single commit once the quality gates pass (:doc:`/devops/quality-gates`).
