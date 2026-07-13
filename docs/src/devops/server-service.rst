Server Service
==============

.. versionadded:: 0.6

The repository ships a hardened systemd **user** service:
``devops/server/systemd/quadrant-server.service``.

.. literalinclude:: ../../../devops/server/systemd/quadrant-server.service
   :language: ini

Install:

.. code-block:: bash

   dart compile exe server/bin/quadrant_server.dart \
     -o ~/.local/bin/quadrant_server
   mkdir -p ~/.config/quadrant-todo ~/.config/systemd/user
   (umask 077; openssl rand -base64 32 > ~/.config/quadrant-todo/token)
   cp devops/server/systemd/quadrant-server.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now quadrant-server
   journalctl --user -u quadrant-server -f

The unit runs the server in the foreground under systemd supervision,
restricted to its vault directory (``ProtectSystem=strict`` +
``ReadWritePaths``). Backups pair with a timer calling
``quadrant_server backup`` (:doc:`database-backup`).
