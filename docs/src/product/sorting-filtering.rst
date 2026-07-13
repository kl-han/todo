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
