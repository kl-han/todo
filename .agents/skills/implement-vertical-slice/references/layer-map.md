# Layer map (where code goes)

| Concern              | Location                                                        |
| -------------------- | --------------------------------------------------------------- |
| Product behavior     | docs/src/product/                                               |
| Wire contract        | api/openapi.yaml                                                 |
| Entity + transitions | packages/quadrant_domain/lib/src/entities/                       |
| Validation rules     | packages/quadrant_domain/lib/src/rules/validation.dart           |
| Commands/queries     | packages/quadrant_application/lib/src/services/                  |
| Repo interfaces      | packages/quadrant_application/lib/src/repositories.dart          |
| SQL                  | packages/quadrant_store/lib/src/repositories/                    |
| HTTP routes          | packages/quadrant_api_server/lib/src/handlers/vault_routes.dart  |
| Typed client         | packages/quadrant_api_client/lib/src/client/                     |
| UI state             | apps/quadrant_todo/lib/state/app_state.dart                      |
| Widgets              | apps/quadrant_todo/lib/presentation/                             |
| Contract tests       | packages/quadrant_conformance/lib/src/suite.dart                 |
| Widget-test fake     | apps/quadrant_todo/test/fake_backend.dart                        |
