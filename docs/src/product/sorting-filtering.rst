Sorting and Filtering
=====================

.. versionadded:: 0.2

Sorting
-------

Task lists have exactly one order, ``matrix_modified_asc``:

.. code-block:: sql

   ORDER BY
       is_urgent DESC,
       is_important DESC,
       updated_at ASC,
       id ASC

Consequences:

* Urgent-and-important (Q1) tasks always lead; urgent-only (Q3) ranks
  above important-only (Q2) because urgency sorts first.
* Within a flag group, the **least recently modified** task comes first —
  the task you have neglected longest surfaces at the top.
* The ``id`` tiebreak makes the order fully deterministic.

Filtering
---------

* ``status=open`` (default), ``completed``, or ``all``; soft-deleted tasks
  are never included, whatever the filter.
* ``quadrant=1..4`` restricts to one derived quadrant.
* ``tag_id=<uuid>`` restricts to tasks carrying the tag.

Filters combine; sorting applies after filtering.

Grouping
--------

.. versionadded:: 2.1

The Tasks view can present the flat list grouped by:

* **tag**,
* **importance/urgency** (the four flag combinations), or
* **tag and importance/urgency together** (tag groups subdivided by
  flags).

Grouping is presentation over the same result set: it combines freely
with the status filter and with filter rules, and inside every group
tasks keep the deterministic ``matrix_modified_asc`` order. Tag groups
show the tag's progress (:doc:`tag-behavior`), which makes group-by-tag
the tag overview surface.

The grouping itself is a deterministic, tested transform (``groupTasks``
in ``quadrant_api_client``) over the fetched task list — the widget tree
only renders the resulting groups, keeping this presentation logic out
of widget code.

Filter rules
------------

.. versionadded:: 2.1

Users can define named filter rules as boolean expressions over task
metadata and apply them to task views. The expression language has:

* the terms ``tag``, ``important``, and ``urgent``;
* comparisons such as ``tag = test1``;
* the operators ``not``, ``and``, ``or``;
* parentheses for explicit grouping.

Precedence, tightest first:

1. parentheses
2. comparisons
3. ``not``
4. ``and``
5. ``or``

So ``important and not tag = someday or urgent`` reads as
``(important and (not (tag = someday))) or urgent``.

Rules are validated as the user edits: validation errors are shown
clearly, and an invalid rule can be neither saved nor applied. A valid
rule is translated into backend/SQLite filtering by the application and
backend layers — never evaluated in widget logic — and composes with
the fixed sort order like any other filter. Rules are created, edited,
validated, and removed in the Editing / Rules tab
(:doc:`/platforms/web/responsive-shell`).

The language itself — lexer, parser, precedence, validation, and a
reference in-memory evaluator — lives in the pure ``quadrant_query``
package. That evaluator defines the reference semantics the
backend/SQLite translation must reproduce, so a rule filters
identically on both backends.

A task query applies a rule through the ``filter`` query parameter
(:doc:`/api/task-api`); the backend advertises the ``filter-rules``
capability when it honors it. The rule composes with the status,
quadrant, and tag filters and with the fixed sort order.
