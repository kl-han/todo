Dependency Management
=====================

* The pure-Dart packages and ``server/`` resolve as **one pub workspace**
  from the repository root; ``pubspec.lock`` at the root is committed for
  reproducible resolution.
* The Flutter app resolves separately (it needs the Flutter SDK) and
  references the shared packages by path.
* Direct dependencies are deliberately few: ``shelf``/``shelf_router``
  (HTTP), ``sqlite3`` (pinned to 2.x — 3.x pulls prebuilt native assets
  at build time, unusable in restricted environments), ``http``,
  ``args``, and the test/lint toolchain. Adding a dependency is a review
  decision, not a convenience.
* Upgrades: ``dart pub outdated`` per milestone; upgrade, run the full
  gate (:doc:`quality-gates`), commit the lockfile change separately from
  features.
* Sphinx/furo versions float within ``docs/pyproject.toml`` constraints;
  the ``-W`` build catches breaking theme/directive changes immediately.
