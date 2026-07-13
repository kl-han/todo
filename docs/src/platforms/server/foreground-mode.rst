Foreground Mode
===============

.. versionadded:: 0.6

Foreground is the default and the recommended mode under any supervisor
(systemd, runit, containers):

.. code-block:: bash

   quadrant_server serve \
     --host 127.0.0.1 --port 8787 \
     --token-file ~/.config/quadrant-todo/token \
     --data-dir ~/.local/share/quadrant-todo/vaults

Behavior:

* Logs to stdout; the first line is the machine-readable
  ``quadrant_server listening on http://HOST:PORT``.
* ``--port 0`` binds an OS-assigned port (tests, ad-hoc runs).
* A bearer token is **required**; ``--token-file`` is preferred because
  ``--token`` leaks into process listings. ``--allow-anonymous`` exists
  for development only and must never be used on an exposed host.
* ``SIGINT``/``SIGTERM`` close the HTTP listener and every open vault,
  then exit 0. Acknowledged writes are already committed, so even
  ``SIGKILL`` loses nothing.
