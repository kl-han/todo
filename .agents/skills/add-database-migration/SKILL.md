# add-database-migration

Trigger: any schema change (new column/table/index).

1. APPEND a new SQL script to `migrations` in
   `packages/quadrant_store/lib/src/migrations/migrations.dart`. Never
   edit a shipped migration — fixes are new migrations.
2. Each migration must be a valid single transaction; the runner wraps it
   in BEGIN/COMMIT with rollback on failure.
3. Update repositories and DTO mapping for the new columns.
4. Tests to add in `packages/quadrant_store/test/`:
   - fresh database reaches the new `schemaVersion`;
   - a database created at the PREVIOUS released version migrates forward
     with data intact (add a fixture per release);
   - reopen idempotence still holds.
5. Update `docs/src/implementation/sqlite-schema.rst` (DDL) and
   `docs/src/reference/database-reference.rst`, with `.. versionchanged::`.
6. The health/capabilities `schema_version` reports migrations.length
   automatically — verify the conformance suite still passes on both
   harnesses.
7. Remember downgrade policy: newer-schema databases refuse to open; say
   so in release notes if the schema moved.
