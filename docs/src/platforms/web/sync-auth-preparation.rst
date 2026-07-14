Sync and Auth Preparation
=========================

The web platform will likely be the primary remote-client surface for
the v3.0 remote backend. These rules keep it ready for remote
authentication without changing core task editing, Matrix, filtering,
or tag behavior — and without smuggling in sync before v3.0 specifies
it.

Remote sync (v3.0)
------------------

* Until the v3.0 implementation is specified, remote mode stays
  entirely separate from local-only behavior: switching backend modes
  switches the visible dataset, and nothing is merged, copied, or
  synchronized (:doc:`/product/backend-modes`).
* The web app implements no offline queue, background reconciliation,
  or other sync shortcut ahead of the documented v3.0 semantics.

Remote auth (v3.0)
------------------

Behavior the v3.0 web client must satisfy; mechanism details (cookie
versus browser storage, token format) are recorded as open decisions in
:doc:`/todo` because browsers offer no OS keychain equivalent to the
secure storage used on iOS and Linux.

* **Where auth state lives** — auth state is scoped to the browser
  profile and the app's origin. Credentials are held in memory for the
  session and, if the user opts into staying signed in, in
  origin-scoped browser storage. They are never embedded in URLs and
  never sent to any origin other than the configured backend.
* **Logout** — logging out clears the stored credentials *and* all
  fetched task data from the session, then returns to the backend
  selection surface. A back-navigation after logout shows no task data.
* **Expired session** — when the backend rejects the session (401), the
  app shows an explicit re-authentication prompt. It never falls back
  to a different dataset and never discards what the user is typing:
  unsent editor contents stay in the form, and after re-authentication
  the app refreshes to server truth before the user resumes.
