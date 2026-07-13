Command Reference
=================

quadrant_server
---------------

.. code-block:: text

   quadrant_server [serve] [options]        Run the server (default).
   quadrant_server vault-create NAME        Create an empty vault.
   quadrant_server backup VAULT DEST        Snapshot a vault (VACUUM INTO).

Options (serve):

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Option
     - Meaning
   * - ``--host``
     - Bind address (default ``127.0.0.1``)
   * - ``--port``
     - TCP port; ``0`` = OS-assigned (default ``8787``)
   * - ``--data-dir``
     - Vault directory (default XDG data dir)
   * - ``--token`` / ``--token-file``
     - Bearer token (file form preferred); required
   * - ``--allow-anonymous``
     - Serve without auth (development only)
   * - ``--daemon``
     - Detach; write ``--pid-file`` and ``--log-file``
   * - ``--pid-file`` / ``--log-file``
     - Daemon bookkeeping locations

Developer commands
------------------

.. code-block:: text

   dart pub get                 Resolve the workspace
   dart analyze --fatal-infos   Lint gate
   dart test <package>          Per-package tests
   make -C docs html            Documentation build
   devops/bootstrap/setup.sh    One-shot environment bootstrap
