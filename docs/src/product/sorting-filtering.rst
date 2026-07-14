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

The Tasks tab may group or aggregate tasks by tag, by importance and
urgency, or by both. Grouping is presentation only: it never changes task
state, tag assignment, or quadrant membership.

Rule filters
------------

Custom task views may be configured with boolean filter rules. Rules use
the keywords ``tag``, ``important``, and ``urgent`` plus ``not``, ``and``,
``or``, parentheses, and comparisons such as ``tag = test1``.

.. code-block:: text

   (tag = test1 and important) or urgent

Precedence is parentheses first, then comparisons, then ``not``, then
``and``, then ``or``. Rules are validated before use. Valid rules are
translated by the application/backend layer into SQLite filtering; UI
widgets do not implement the business rule or build ad hoc storage
queries.
