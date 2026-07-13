Usage Tracking
==============

.. versionadded:: 1.4

The desktop agent can record which application holds the foreground —
**off until explicitly enabled**, event-driven (no polling), and local
by default. Design and full policy: :doc:`/post-v1/usage-tracking` and
:doc:`/post-v1/privacy`.

What the user observes:

* Nothing is collected until tracking is turned on; the agent status
  route reports the current tracking state openly.
* One interval per stretch of foreground use: it closes on focus
  change, idle, lock/suspend, or agent shutdown. Durations come from a
  monotonic clock — wall-clock jumps can never distort them.
* **Collected**: application identity (``app_id``), duration. **Not
  collected**: keystrokes, mouse positions, screenshots, clipboard,
  URLs — ever; window titles only behind a separate opt-in.
* Controls: pause for N minutes (auto-expires, never survives a
  restart), private mode (closes the current interval immediately),
  an application exclusion list (excluded apps never enter intervals
  or aggregates), delete-all.
* Raw intervals are kept 7 days by default (configurable), then
  pruned; the day × application aggregates are small, less sensitive,
  and kept long-term in the separate ``usage.sqlite3``
  (:doc:`/decisions/adr-0007-separate-usage-database`). Deleting usage
  history never touches tasks.
* No usage data leaves the device; remote aggregate upload remains off
  and unimplemented until a later milestone.
