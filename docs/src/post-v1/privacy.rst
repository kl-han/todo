Low-Intrusion Privacy Design
============================

Default policy
--------------

.. code-block:: text

   Usage tracking:       Off until enabled
   Application identity: Collected
   Category:             Collected
   Window title:         Not collected
   Browser URL:          Never collected
   Keystrokes:           Never collected
   Screenshots:          Never collected
   Remote upload:        Off
   Raw retention:        7 days
   Aggregate retention:  User-configurable

User controls
-------------

Provide:

* Pause for 15 minutes.
* Pause until tomorrow.
* Private mode.
* Application exclusion list.
* Category override.
* Delete today's data.
* Delete all usage data.
* Export usage data.
* Disable startup.
* Disable remote aggregate upload.
* Visible tracking status in the tray/UI.

Resource goals
--------------

Because this is a post-v1 real product feature, define measurable
intrusion limits:

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Resource
     - Initial goal
   * - Idle CPU
     - Effectively zero between events
   * - Average CPU
     - Below 0.5% during normal desktop use
   * - Memory
     - Below 50 MB
   * - Periodic idle check
     - No more than once every 30 seconds
   * - Disk writes
     - On focus change, or batched every 60 seconds
   * - Network
     - No traffic unless remote upload is enabled
   * - Privilege
     - No root/admin
   * - Input access
     - No raw keyboard/mouse hooks

These are engineering targets, not guarantees, until measured on
Windows and the Latitude/Sway environment.
