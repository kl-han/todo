iOS Storage and Security
========================

.. versionadded:: 0.4

Vault location
--------------

``~/Library/Application Support/quadrant-todo/default.sqlite3`` inside
the app sandbox: included in device backups, never user-visible, and not
subject to Caches purging. (Documents is avoided so the database is not
exposed in the Files app.)

Credentials
-----------

Remote-mode credentials (v0.7) go through the ``CredentialStore``
abstraction (``quadrant_backend_host``):

* iOS implementation: **Keychain**, with
  ``kSecAttrAccessibleAfterFirstUnlock`` so a resumed app can
  reauthenticate without user interaction.
* The interface is deliberately tiny (``read``/``write``/``delete`` by
  key) so the Keychain plugin binds in the app layer without leaking into
  shared packages.

The embedded backend's per-launch token is never stored — not in the
Keychain, not on disk. It lives in process memory and dies with the
launch, which is exactly the property that makes the loopback server safe.
