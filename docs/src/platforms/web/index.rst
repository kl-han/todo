Web
===

.. note::

   The web platform is planned scope for the v2.1 web milestone and the
   v3.0 remote sync/auth milestone (:doc:`/intro/roadmap`). Nothing on
   these pages is implemented yet; they define the behavior the web
   implementation must satisfy, following the specification-first cycle
   (:doc:`/agents/feature-workflow`). Unresolved cross-cutting points
   are tracked in :doc:`/todo`.

The web app runs in a browser and connects to a backend over HTTP using
the shared REST client (``packages/quadrant_api_client``). It never
opens local SQLite files and never imports backend store internals.
Browser layout and input conventions may differ from Linux and mobile,
but every task rule — quadrant derivation, tags, urgency, importance,
completion, filtering, editing, versioning — remains identical.

The web platform is a first-class UI target of the one shared widget
tree (:doc:`/platforms/shared-ui`), not a separate product. Its
responsibilities:

* render the **Matrix**, **Tasks**, and **Editing / Rules** tabs;
* apply the same task, tag, urgency, importance, completion, filtering,
  and editing semantics as every other platform;
* communicate only through ``packages/quadrant_api_client``;
* support responsive layouts for desktop browsers, tablets, and narrow
  mobile browsers;
* support mouse, keyboard, touch, and accessible interaction patterns.

Backend modes
-------------

The browser is a REST client; it treats every backend as an HTTP
service. Switching backend modes switches the source of truth exactly
as documented in :doc:`/product/backend-modes` — nothing is merged,
copied, or synchronized between modes.

* **Local embedded backend** — only if the hosting/runtime model
  supports it. A plain browser tab cannot host the embedded loopback
  isolate (no local SQLite, no in-process HTTP listener), so a browser
  deployment has no local mode. A future desktop shell that embeds the
  web UI next to an embedded backend would still have to expose it over
  HTTP through the REST client.
* **Standalone server backend** — the primary mode: the web app is a
  window onto a vault hosted by the user's own server
  (:doc:`/platforms/server/index`), reached at a configurable base URL
  (:doc:`backend-connectivity`).
* **Remote backend (v3.0)** — the future sync/auth-capable remote
  backend. The web platform is expected to be the primary remote-client
  surface; preparation is specified in :doc:`sync-auth-preparation`.

.. toctree::
   :maxdepth: 2

   responsive-shell
   interaction-model
   backend-connectivity
   sync-auth-preparation
   accessibility
