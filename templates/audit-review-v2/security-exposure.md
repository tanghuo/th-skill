# Security Exposure Audit

```text
Audit secret leakage, privacy exposure, unsafe logging, and supply-chain or
operational exposure.

Starting points to customize:
- Config, env, deployment, and CI files: {{config_paths}}
- Logs and error responses: {{logging_paths}}
- Public file/static/export/download endpoints: {{exposure_paths}}
- Dependency and build tooling: {{dependency_paths}}

Check:
- Secrets committed, echoed, logged, returned in responses, or exposed through
  debug endpoints.
- PII or sensitive business data appears in logs, metrics labels, traces, URLs,
  object keys, exported files, or error messages.
- Public endpoint serves private files or predictable object paths.
- CORS, callback validation, signature validation, or webhook replay protection
  is weak.
- Dependency pinning, build script, or installer can execute unexpected code.
- Debug/profiling/admin endpoints are reachable in production.
- Backup, dump, or report files are generated with unsafe permissions or names.

For each finding, include the exposure path, data or secret involved, attacker
or accidental-reader model, blast radius, and minimal repair direction.
```
