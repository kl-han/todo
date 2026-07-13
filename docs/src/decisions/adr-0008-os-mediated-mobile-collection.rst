ADR-0008: OS-Mediated Usage Collection on Mobile
================================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

The desktop agent model (:doc:`adr-0006-per-user-usage-agent`) does not
transfer to mobile. Android restricts long-running background work and
already maintains application usage history itself; iOS does not permit
a general usage-tracking daemon at all.

Decision
--------

Mobile platforms do not imitate a permanently running desktop daemon.

* **Android** imports the OS-maintained history via
  ``UsageStatsManager`` after the user grants the special
  ``PACKAGE_USAGE_STATS`` access, with ``WorkManager`` scheduling
  periodic imports and a re-import on app open. No Accessibility
  Service, and no permanent foreground service merely to poll usage.
* **iOS** uses Apple's Screen Time technology (``FamilyControls``,
  ``DeviceActivity``, ``DeviceActivityReport``, ``ManagedSettings``)
  only if the entitlement proves available; otherwise tracking is
  app-only (in-app time and Pomodoro sessions).

Consequences
------------

* Android ingestion is not immediate: background work may be delayed,
  and precision varies by version and vendor. The importer must be
  idempotent over event ranges.
* If Usage Access is revoked, collection stops and the UI shows a clear
  status.
* iOS usage reporting stays an optional capability behind a flag until
  the entitlement and data model are proven; the product must not
  promise desktop-equivalent tracking on iOS.
* Both platforms keep the embedded backend; only desktops move to the
  agent-hosted backend.
