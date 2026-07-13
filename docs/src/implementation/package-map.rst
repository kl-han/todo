Package Map
===========

.. code-block:: text

   quadrant-todo/
   ├── api/                     # openapi.yaml, examples, problem-types
   ├── apps/quadrant_todo/      # Flutter app (needs Flutter SDK)
   │   └── lib/{bootstrap,presentation,platform}
   ├── packages/
   │   ├── quadrant_domain/         # entities, rules, value_objects
   │   ├── quadrant_application/    # commands, queries, services,
   │   │                            # repository interfaces
   │   ├── quadrant_store/          # database, migrations, repositories
   │   ├── quadrant_api_server/     # handlers, middleware, dto, routing
   │   ├── quadrant_api_client/     # client, dto, errors
   │   ├── quadrant_backend_host/   # embedded_backend, remote_profile,
   │   │                            # backend_lifecycle
   │   └── quadrant_conformance/    # BackendContractSuite + harnesses
   ├── server/                  # standalone quadrant_server executable
   ├── devops/                  # bootstrap, ci, systemd, release
   └── docs/                    # this Sphinx tree

The pure-Dart packages and ``server/`` resolve together as one pub
workspace from the repository root. The Flutter app is deliberately
outside the workspace so nothing but ``apps/quadrant_todo`` requires the
Flutter SDK. Dependency directions are documented in
:doc:`/architecture/conceptual-layers`.
