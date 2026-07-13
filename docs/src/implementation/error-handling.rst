Error Handling
==============

.. versionadded:: 0.5

One taxonomy end to end (:doc:`/architecture/error-model`):

.. code-block:: text

   domain/application          REST boundary                client / UI
   ─────────────────────────   ──────────────────────────   ─────────────────────────
   DomainValidationError    →  400 problems/validation   →  message near the input
   EntityNotFoundException  →  404 problems/not-found    →  refresh (item vanished)
   StateConflictException   →  409 problems/conflict     →  message (e.g. name taken)
   VersionConflictException →  412 problems/version-conflict → silent refresh-to-truth
   transport failure        →  (no response)             →  offline banner + retry

UI rules:

* **412 is not an error to show**: someone (perhaps another window)
  changed the task first. ``AppState`` refreshes so the user sees current
  state and re-applies deliberately.
* **Transport failure is never silent** and never triggers a dataset
  fallback: the banner names the problem and offers retry; local mode
  additionally attempts an embedded-backend restart.
* **Unexpected non-problem errors** (``UnexpectedResponseException``)
  surface verbatim — they indicate a contract bug and must be reported,
  not smoothed over.
