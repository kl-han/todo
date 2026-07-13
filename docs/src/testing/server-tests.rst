Server Tests
============

.. versionadded:: 0.6

``server/test`` exercises the standalone server as an operator would:

* **VaultManager units**: strict name validation (uppercase, spaces,
  traversal, over-length all rejected), lazy ``default`` creation,
  explicit creation for everything else, duplicate rejection, and dataset
  isolation between vaults.
* **Real process serve**: launches ``quadrant_server`` as a subprocess;
  asserts a missing token refuses to start, ``vault-create`` works, the
  vaults listing shows every vault, HTTP writes land in the addressed
  vault only, unknown vaults 404 instead of being created, and SIGTERM
  exits 0.
* **Backup subcommand**: snapshot of a populated vault reopens with the
  data.
* **Daemon lifecycle**: ``--daemon`` detaches, the child writes its pid
  file and logs the listening line, and SIGTERM removes the pid file on
  the way down.

Plus the conformance suite (:doc:`backend-conformance`), which runs the
whole REST contract against the same subprocess.
