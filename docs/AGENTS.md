# Documentation rules (docs/)

- The build must stay warning-free: `sphinx-build -W --keep-going -b html
  docs/src docs/build/html`. A new page must be reachable from its
  section's `toctree`.
- Do not duplicate the OpenAPI schema; `api/openapi.yaml` is normative
  and pages summarize it.
- Use `literalinclude` for content that must match the repository
  exactly (e.g. the systemd unit); never paste code that can drift.
- Mark behavior changes with `versionadded` / `versionchanged` /
  `deprecated` tied to roadmap versions.
- Page placement: product behavior in `product/`, boundaries and
  rationale in `architecture/`, wire summaries in `api/`,
  platform-specific decisions in `platforms/`, code locations in
  `implementation/`, procedures in `devops/`, ADRs in `decisions/`.
- Every feature PR updates the applicable pages; docs are part of the
  feature, not a cleanup stage.
