Report API
==========

.. versionadded:: 1.7

Normative definitions live in ``api/openapi.yaml``; this page summarizes.

.. list-table::
   :header-rows: 1
   :widths: 10 50 40

   * - Method
     - Route
     - Purpose
   * - ``GET``
     - ``/vaults/{id}/reports/weekly?week_start=``
     - Compute the weekly report (``format=json|csv``)
   * - ``PUT``
     - ``/vaults/{id}/reports/weekly/{week_start}/snapshot``
     - Finalize: store the snapshot with user notes
   * - ``GET``
     - ``/vaults/{id}/reports/weekly/{week_start}/snapshot``
     - Read the finalized snapshot

Semantics worth remembering:

* ``week_start`` must be a Monday; anything else is a 400 validation
  problem.
* Reports are pure reads — computed, never stored. Finalizing
  recomputes and stores per week (insert-or-replace) with a
  ``report_version`` so later builds can migrate snapshots.
* CSV is a flat ``section,metric,value`` table for spreadsheets.
