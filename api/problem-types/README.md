# Problem type registry

Every non-2xx response uses RFC 9457 Problem Details
(`application/problem+json`). Problem `type` values are relative URIs under
`https://quadrant-todo.invalid/problems/` and are registered here, one file
per type, as they are introduced.

| Type                  | Status | Meaning                                     |
| --------------------- | ------ | ------------------------------------------- |
| `about:blank`         | any    | Generic problem; `title` matches the status |
| `problems/unauthenticated` | 401 | Missing or invalid `Authorization` header |
| `problems/not-found`  | 404    | Resource or route does not exist            |
