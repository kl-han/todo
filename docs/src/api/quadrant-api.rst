Quadrant API
============

.. versionadded:: 0.2

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/quadrants?status=open``
     - All four grouped task collections and counts

The response always contains exactly four groups in quadrant order, each
with ``quadrant`` (1–4), ``count``, and the group's ``tasks`` in matrix
order. Membership is derived per request:

.. code-block:: text

   Q1 = urgent && important
   Q2 = !urgent && important
   Q3 = urgent && !important
   Q4 = !urgent && !important

One request renders the whole matrix screen; there is no per-quadrant
endpoint to drift out of sync with.
