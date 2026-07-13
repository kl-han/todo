Command and Query Flow
======================

.. versionadded:: 0.2

Example command — toggle completion from the UI:

.. code-block:: text

   widget tap / Enter
     → QuadrantApiClient.updateTask(id, status: 'completed',
                                    ifMatchVersion: seen)
     → PATCH /api/v1/vaults/default/tasks/{id}  If-Match: "7"
     → handler parses body + If-Match           (api_server)
     → TaskService.update(...)                  (application)
     → Task.complete(now)                       (domain)
     → TaskRepository.update(task)              (store, commits)
     ← 200 + task JSON + ETag "8"
     ← TaskDto → widget rebuild

Failure paths are typed the whole way: a stale version raises
``VersionConflictException`` in the service, becomes a 412 problem at the
boundary, and surfaces as ``ProblemDetailsException(status: 412)`` in the
client.

Queries follow the same path with no side effects: repository queries are
already filtered (deleted rows excluded) and sorted (matrix order) in SQL,
so every consumer sees identical ordering.
