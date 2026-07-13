ADR-0001: Flutter for iOS and Linux
===================================

:Status: Accepted
:Date: 2026-07-13

Context
-------

The product must run on an iPhone and on Arch Linux under Sway/Wayland
from one codebase maintained by one person.

Decision
--------

Use Flutter with a single shared presentation layer, plus small
platform-specific layers for iOS navigation/lifecycle and Linux
keyboard/Wayland behavior.

Consequences
------------

* One UI codebase; platform work is limited to interaction conventions,
  not features.
* Dart everywhere allows the backend, client, and app to share a language
  and a workspace.
* The Linux embedding runs under Wayland via GTK; Sway-specific behavior
  is validated on the real compositor (v0.3).
* Flutter lifecycle notifications are not guaranteed to be delivered, so
  no correctness rule may depend on them
  (:doc:`/architecture/backend-lifecycle`).
