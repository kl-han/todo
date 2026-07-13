Weekly Review
=============

.. versionadded:: 1.7

The weekly review is a computed report over one Monday-started week —
**facts only**. The backend counts; it never judges. Interpretations
("Q2 got less time than planned") and recommendations ("move one Q2
task into Monday") belong to the presentation layer, exactly as the
design prescribes (:doc:`/post-v1/weekly-review`).

Sections computed from the vault:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Section
     - Calculation
   * - Completed tasks
     - Count by quadrant, plus completed occurrences
   * - Carryover
     - Planned items without a ``done`` outcome (undecided, skipped,
       moved)
   * - Due-date performance
     - On-time / late / overdue-open for dues inside the week
   * - Focus time
     - Session count, active seconds, interruptions
   * - Plan accuracy
     - Planned minutes versus actual focus seconds
   * - Q2 investment
     - Focus seconds on important/non-urgent tasks
   * - Delegated follow-up
     - Open Q3 tasks
   * - Cleanup candidates
     - Open Q4 tasks untouched for 14+ days

Application-usage and distraction sections come from the agent's
``usage.sqlite3`` (:doc:`/api/agent-api`) and join client-side — the
task vault never sees behavioral data.

Reports are computed on demand. **Finalizing** a week stores a
versioned snapshot with the user's notes; only finalized weeks are
stored. ``format=csv`` exports flat ``section,metric,value`` rows.
