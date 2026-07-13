Daemon Mode
===========

.. versionadded:: 0.6

For hosts without a supervisor, ``--daemon`` re-executes the server
detached from the terminal (Dart has no ``fork``; a detached re-exec with
an internal marker flag is the portable equivalent):

.. code-block:: bash

   quadrant_server serve --daemon \
     --token-file ~/.config/quadrant-todo/token \
     --pid-file "$XDG_RUNTIME_DIR/quadrant-server.pid" \
     --log-file ~/.local/share/quadrant-todo/quadrant-server.log

* The launcher prints the child pid and the pid/log file locations, then
  exits.
* The daemon writes its own pid file on startup and **removes it** on
  clean shutdown; timestamps prefix every log line.
* Stop with ``kill -TERM $(cat "$XDG_RUNTIME_DIR/quadrant-server.pid")``.

Defaults: pid file under ``$XDG_RUNTIME_DIR``, log file next to the data
directory. Under systemd, prefer foreground mode and journald
(:doc:`/devops/server-service`).
