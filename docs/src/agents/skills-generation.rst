Skills Generation
=================

Repository skills live in ``.agents/skills/<skill-name>/`` with lowercase
hyphenated names:

.. code-block:: text

   skill-name/
   ├── SKILL.md       # trigger description + the reusable procedure
   ├── references/    # detailed schemas or checklists
   ├── scripts/       # only for deterministic repeated actions
   └── assets/        # templates used in generated output

Procedure for creating one:

1. Define the example requests that should trigger the skill.
2. Identify the steps that repeat across those requests.
3. Move anything that is a permanent rule to ``AGENTS.md`` instead.
4. Keep only the reusable procedure in ``SKILL.md``.
5. Put large schemas and long checklists in ``references/``.
6. Add scripts only where automation is deterministic.
7. Validate metadata and naming.
8. Run the skill on a representative feature.
9. Check the resulting code, tests, and documentation.
10. Revise the skill whenever the same review problem recurs.

Skills must not duplicate the architecture documentation — they link to
it. The initial set: ``implement-vertical-slice``,
``update-rest-contract``, ``add-database-migration``,
``verify-backend-conformance``, ``prepare-release``.
