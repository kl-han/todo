REST Boundary
=============

Every application operation crosses HTTP, in both modes:

.. code-block:: text

   Flutter UI ─ typed REST client ─┬─ loopback HTTP ─ embedded isolate ─ SQLite   (local)
                                   └─ HTTPS ─ standalone server ─ SQLite vault    (remote)

REST is the **platform-independent boundary** of the system — it is not a
platform-specific design. Platform-specific work concerns iOS
lifecycle/navigation and Linux Wayland/keyboard behavior only.

Consequences
------------

* There is exactly one implementation of every route
  (``quadrant_api_server``); both backends build their handler from
  ``buildApiHandler``. A route existing on one backend and not the other is
  a defect by definition.
* The presentation layer depends only on ``quadrant_api_client``. It never
  imports SQLite models or store internals.
* Business rules live in the domain and application layers behind the
  handlers; REST handlers translate HTTP to commands and queries, nothing
  more.
* The contract is normative in ``api/openapi.yaml``; conformance is proven
  per change by the suite described in
  :doc:`/testing/backend-conformance`.

The decision and its trade-offs are recorded in
:doc:`/decisions/adr-0002-rest-everywhere`.
