Conceptual Layers
=================

.. code-block:: text

   presentation  →  api_client
   bootstrap     →  api_client + backend_host
   api_server    →  application
   application   →  domain + repository interfaces
   store         →  repository interfaces (implements them)
   server        →  api_server + store

Prohibited dependencies (checked in review, enforced by pubspecs):

* Presentation importing SQLite models or the store.
* REST handlers containing quadrant or validation rules.
* The local backend having routes absent from the remote backend.
* Platform code bypassing the REST client.

Layer responsibilities
----------------------

* **Domain** (``quadrant_domain``): entities, transitions, validation.
* **Application** (``quadrant_application``): services orchestrating
  repositories and domain transitions; defines ``TaskRepository`` /
  ``TagRepository`` interfaces and typed failures.
* **Store** (``quadrant_store``): SQLite schema, migrations, repository
  implementations. The only package that touches SQLite.
* **API server** (``quadrant_api_server``): HTTP translation — routing,
  auth, ETag/If-Match, Problem Details. One implementation for all
  backends.
* **API client** (``quadrant_api_client``): typed access for the UI.
* **Backend host** (``quadrant_backend_host``): embedded isolate lifecycle
  and remote profiles.
