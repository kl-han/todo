Linux Engineering Decisions
===========================

.. versionadded:: 0.3

* **Vim-style focus movement** (``h/j/k/l``) instead of arrow-only: the
  target user runs Sway; arrows also work via standard traversal, so this
  is additive.
* **Suppression over mode-switching**: letter shortcuts are suppressed
  during text input rather than introducing a modal "normal/insert"
  scheme. A todo app should not require learning modes.
* **XDG paths, no dot-dirs in $HOME**: data under ``$XDG_DATA_HOME``,
  future config under ``$XDG_CONFIG_HOME``.
* **No tray/daemon behavior**: process lifetime equals window lifetime;
  the standalone server (v0.6) is the answer for always-on needs.
* **NavigationBar at the bottom on Linux too**: one shell for both
  platforms beats a platform-forked scaffold; Alt+number switching makes
  the pointer target irrelevant on Sway.
