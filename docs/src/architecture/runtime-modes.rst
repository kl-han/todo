Runtime Modes
=============

.. list-table::
   :header-rows: 1

   * - Property
     - Local mode
     - Remote mode
   * - HTTP destination
     - ``127.0.0.1:<ephemeral>``
     - Configured HTTPS URL
   * - Server lifetime
     - Flutter application lifetime
     - Independent process
   * - Database
     - Application-local SQLite
     - Server vault SQLite
   * - Authentication
     - Random launch token
     - Persistent bearer token
   * - Offline operation
     - Yes
     - No
   * - Data transfer between modes
     - No
     - No
   * - API contract
     - Same v1 contract
     - Same v1 contract

Local mode
----------

The application process spawns a dedicated backend isolate that owns the
HTTP listener, REST routing, SQLite connection, application services, and
migrations. Startup: load configuration, spawn the isolate, open and
migrate the database, bind ``127.0.0.1`` port ``0`` (the OS assigns an
unused port), generate a per-launch token, report port and token to the UI
isolate, wait for ``/api/v1/health``, construct the REST client, render.

Remote mode
-----------

Remote mode skips the embedded backend and points the same typed client at
a standalone server with a stored credential. Remote mode is online-only
through v1.0: if the server is unreachable the UI shows an explicit
offline error and **never** silently falls back to the local database.

Changing modes changes the active dataset. Import, export, migration, and
synchronization between datasets are separate future capabilities
(:doc:`/decisions/adr-0005-no-sync-before-v1`).
