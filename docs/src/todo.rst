Open Questions
==============

Unresolved, cross-cutting points from accepted plans. Each item is
resolved by a normal feature change (behavior page + ADR where needed),
after which it is removed from this list.

From the web platform plan (v2.1 / v3.0)
----------------------------------------

* **Third tab across platforms.** The web shell's three tabs are
  Matrix, Tasks, and Editing / Rules; iOS and Linux currently ship
  Matrix, Tasks, and Tags. Group-by-tag in the Tasks tab covers the tag
  overview, but whether iOS and Linux replace the Tags tab with
  Editing / Rules (keeping one shell everywhere) is undecided.
* **Tag names with spaces.** v2.1 forbids spaces in tag names so inline
  ``#`` entry can terminate on space. Whether existing tag names
  containing spaces need a migration (rename, or reject-on-edit) is
  undecided (:doc:`/product/tag-behavior`).
* **Touch drag versus move controls.** On touch browsers the Matrix
  needs either touch drag or explicit move controls
  (:doc:`/platforms/web/interaction-model`); which one ships first is
  an implementation-time decision, but the accessible fallback is
  required either way.
* **Browser auth-state mechanism.** v3.0 web auth defines behavior
  (origin-scoped state, logout clears everything, explicit re-auth on
  401) but not mechanism — cookie versus origin-scoped storage, token
  format, and "stay signed in" persistence need an ADR before v3.0
  (:doc:`/platforms/web/sync-auth-preparation`).
* **CORS policy for the standalone server.** A web app served from a
  different origin than its backend requires the server to answer
  preflights; the allowed-origin policy is a server-side decision
  (:doc:`/platforms/web/backend-connectivity`).
* **Version numbering.** The web milestone is provisionally labelled
  v2.1 and remote sync/auth v3.0 (:doc:`/intro/roadmap`); renumbering
  is free until either milestone starts.
