Release Process
===============

Release builds are produced by the ``Release build`` GitHub Actions workflow
in ``.github/workflows/release-build.yml``.

Automatic builds
----------------

Every push to the ``master`` branch starts a release build. The workflow
builds:

* the standalone server with ``make dist-server``;
* the Linux desktop release bundle with ``make dist-linux``.

Both outputs are uploaded as workflow artifacts:

* ``quadrant-server-linux-x64`` contains the compiled server executable;
* ``quadrant-todo-linux-x64`` contains the Flutter Linux release bundle.

Manual builds
-------------

The same workflow also supports GitHub's manual ``workflow_dispatch`` trigger.
Use **Run workflow** from the Actions tab and choose the branch to build. This
is the release-candidate path for feature or stabilization branches before
they are merged to ``master``.

iOS releases are not built by this workflow because they require signing
identity, provisioning profile, and App Store credentials. Build iOS archives
from a configured macOS host as described in :doc:`ios-build-signing`.
