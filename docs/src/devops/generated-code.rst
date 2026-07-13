Generated Code
==============

Current policy: this repository has **no checked-in generated Dart** —
DTOs and clients are small enough to write and review by hand, and the
conformance suite pins them to the contract. That is a deliberate trade
against generator drift.

What *is* generated, and its rules:

* **Flutter platform runners** (``apps/quadrant_todo/ios``, ``linux``)
  come from ``flutter create`` on a workstation and are host artifacts;
  all behavior lives in ``lib/``. They are not sources of truth.
* **Documentation HTML** (``docs/build``) is never committed.
* If OpenAPI-based generation is ever adopted, the generator output must
  be reproducible (``dart run build_runner build`` or equivalent), CI
  must reject committed files that differ from regeneration, and
  generated files are never edited directly — fixes go into the schema or
  the generator config.
