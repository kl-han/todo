System Context
==============

.. code-block:: text

   ┌────────────────────────────┐
   │ Flutter UI (iOS or Linux)  │
   └─────────────┬──────────────┘
                 │ typed REST client
        ┌────────┴────────┐
        │ local mode      │ remote mode
        ▼                 ▼
   ┌───────────────┐  ┌────────────────────┐
   │ Embedded HTTP │  │ Standalone HTTP    │
   │ server        │  │ server             │
   │ (backend      │  │ (independent       │
   │  isolate)     │  │  process)          │
   └───────┬───────┘  └─────────┬──────────┘
           └────────┬───────────┘
                    ▼
        ┌───────────────────────┐
        │ Shared REST handlers  │
        └───────────┬───────────┘
                    ▼
        ┌───────────────────────┐
        │ Application and       │
        │ domain services       │
        └───────────┬───────────┘
                    ▼
        ┌───────────────────────┐
        │ Repository interface  │
        │ → SQLite              │
        └───────────────────────┘

Actors and stores:

* **The user** interacts only with the Flutter UI.
* **The Flutter UI** holds no business rules and no storage; it renders
  state fetched over HTTP and issues commands over HTTP.
* **Backends** are interchangeable hosts of the same handler stack.
* **SQLite** is the only persistent store; in remote mode it lives with
  the server as one file per vault.
