Domain Model
============

.. versionadded:: 0.2

Two entities, both immutable values in ``quadrant_domain``:

Task
   ``id``, ``title``, ``notes``, ``is_urgent``, ``is_important``,
   ``created_at``, ``updated_at``, ``completed_at?``, ``deleted_at?``,
   ``version``. Status (open/completed) is derived from ``completed_at``;
   the quadrant is derived from the two flags. Every transition —
   ``edit``, ``complete``, ``reopen``, ``softDelete``, ``restore``,
   ``touch`` — funnels through one constructor that increments ``version``
   and refreshes ``updated_at``, so no mutation can forget the concurrency
   bookkeeping.

Tag
   ``id``, ``name``, ``color``, timestamps, ``deleted_at?``, ``version``.
   Progress (completed/total of its live tasks) is a read model, not
   state.

Derived, never stored
---------------------

Quadrant and status are computed properties. Storing them would create a
second source of truth that could drift; deriving them makes reclassification
and toggling trivially correct.

Validation
----------

Domain rules (title/notes/tag-name lengths, ``#rrggbb`` colors) live in
``quadrant_domain/rules`` and throw ``DomainValidationError``, which the
REST boundary maps to 400 problems. Handlers and widgets contain no rules.
