Backend Modes
=============

What the user observes:

* **Local mode** (default): the app owns its data. It works with no
  network, instantly, and its data never leaves the device.
* **Remote mode**: the app is a window onto a vault hosted by the user's
  own server. It requires connectivity; without it the app shows an
  explicit offline error and no task data.

Switching modes switches the visible dataset entirely. Tasks created in
local mode do not appear in remote mode or vice versa; nothing is merged,
copied, or synchronized before v1.0.

.. versionadded:: 0.7

The backend settings sheet (gear icon) selects the mode. Remote mode asks
for the server URL, vault, and bearer token (stored in the platform's
secure storage), offers **Test connection** diagnostics that name the
first failing check (unreachable / rejected credential / wrong API
version / missing vault), and always confirms before switching so the
change of dataset is never accidental. If the configured server speaks an
incompatible API version the app says so plainly rather than degrading.
