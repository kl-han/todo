Sway and Wayland
================

.. versionadded:: 0.3

The Linux target is Arch Linux running Sway (Wayland). Design
consequences:

* The Flutter GTK embedding runs as a native Wayland client; no X11
  assumptions anywhere (no global hotkeys, no window positioning).
* Sway users live on the keyboard: every workflow must be completable
  without a pointer (:doc:`keyboard-navigation`).
* Tiling means arbitrary window sizes: the matrix grid and lists must lay
  out sanely from phone-narrow to ultrawide; nothing may assume a fixed
  window.
* No system tray or background presence: closing the window ends the
  process, and the embedded backend dies with it — which is safe, because
  acknowledged writes are already committed
  (:doc:`/architecture/backend-lifecycle`).

Verification on a real Sway session (v0.3 exit): launch, resize through
tiling layouts, workspace switches, and close/reopen with data intact.
