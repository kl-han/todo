Documentation Build
===================

.. code-block:: bash

   make docs                # root wrapper for the warning-free HTML build
   make html                # build docs, then serve docs/build/html locally
   make -C docs html        # sphinx-build -W --keep-going -b html
   make -C docs linkcheck   # external link verification

Rules
-----

* Warnings are errors (``-W``): a broken cross-reference, orphan page, or
  malformed directive fails the build and therefore CI.
* Use ``literalinclude`` for any code that must exactly match the
  repository; never paste code that can drift.
* Do not duplicate the OpenAPI schema across pages; ``api/openapi.yaml``
  is the single source and pages summarize it.
* Mark behavioral changes with ``versionadded``, ``versionchanged``, and
  ``deprecated`` directives tied to roadmap versions.
* Every feature change updates the applicable pages in the same pull
  request; documentation is part of the feature, not a cleanup stage.
