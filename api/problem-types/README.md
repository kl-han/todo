# Problem type registry

Every non-2xx response uses RFC 9457 Problem Details
(`application/problem+json`). Problem `type` values are relative URIs and
are registered here as they are introduced.

| Type                          | Status | Meaning                                          |
| ----------------------------- | ------ | ------------------------------------------------ |
| `about:blank`                 | any    | Generic problem; `title` matches the status      |
| `problems/unauthenticated`    | 401    | Missing or invalid `Authorization` header        |
| `problems/not-found`          | 404    | Vault, route, task, or tag does not exist        |
| `problems/validation`         | 400    | Malformed request or domain validation failure   |
| `problems/conflict`           | 409    | Contradicts current state (duplicate tag name)   |
| `problems/version-conflict`   | 412    | Stale `If-Match`; body carries `current_version` |
