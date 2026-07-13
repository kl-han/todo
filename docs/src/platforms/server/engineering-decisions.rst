Server Engineering Decisions
============================

.. versionadded:: 0.6

* **Foreground-first**: supervisors do process management better than a
  home-grown daemon; ``--daemon`` exists for supervisor-less hosts, not
  as the recommended path.
* **Detached re-exec instead of fork**: the Dart VM cannot ``fork(2)``;
  a re-exec with ``--_daemonized`` keeps one code path for both modes.
* **Mandatory bearer token** with an explicit, ugly opt-out flag: an
  unauthenticated server should require typing something embarrassing.
* **Explicit vault creation**: implicit creation on first request would
  turn URL typos into datasets and make ``GET /api/v1/vaults`` lie.
* **loopback default bind**: exposing the server beyond ``127.0.0.1``
  (e.g. behind a TLS-terminating reverse proxy) is an operator decision,
  not a default.
* **`VACUUM INTO` backups** shared with local mode — one snapshot
  mechanism, tested once, used everywhere.
