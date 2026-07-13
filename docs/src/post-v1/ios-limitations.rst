iOS Limitation
==============

Do not promise detailed iOS application tracking equivalent to the
desktop or Android collectors. iOS cannot support a general,
unrestricted usage-tracking daemon.

The supported route is Apple's Screen Time technology:

* ``FamilyControls``.
* ``DeviceActivity``.
* ``DeviceActivityReport`` extension.
* ``ManagedSettings`` where appropriate.

These APIs preserve privacy and require Family Controls configuration
and, for distribution, the corresponding entitlement.

Recommended v1.x scope
----------------------

* Track Pomodoro sessions created inside this application.
* Track time spent inside this application.
* Experiment with ``DeviceActivity`` reports behind a capability flag.
* Treat general iOS app-usage reporting as optional until the
  entitlement and the data model are proven.
