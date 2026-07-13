Quality Gates
=============

Every pull request must pass, in order:

1. ``dart analyze --fatal-infos`` — zero findings.
2. Package test suites (domain, application, store, api_server,
   api_client, backend_host, server).
3. **Backend conformance** — the whole REST contract against a real
   embedded isolate and a real standalone server process. This is the
   gate that catches local/remote divergence.
4. ``sphinx-build -W`` — documentation builds warning-free; the linkcheck
   job is advisory.
5. Flutter widget tests (``flutter test``) on a workstation with the SDK;
   integration tests on the target platforms per the testing pages.

Merge policy: features land as one squash commit per branch via the
auto-merge workflow (see ``CONTRIBUTING.md``); a PR is marked ready only
after gates 1–4 have run locally or in CI.

Hardening additions (v0.8): conformance asserts additive tolerance
(unknown request fields ignored), stale-``If-Match`` conflicts on both
PATCH and DELETE, and clean 401 problems for bad credentials.
