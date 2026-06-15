# Release And Operations Audit

```text
Audit release compatibility, migrations, startup safety, scripts, rollback, and
environment-dependent behavior.

Starting points to customize:
- Migration and schema scripts: {{migration_paths}}
- Deployment/install/start/rollback scripts: {{deploy_script_paths}}
- Runtime config and validation: {{config_paths}}
- Compose, systemd, Kubernetes, CI, or release workflow files:
  {{deployment_manifest_paths}}

Check:
- Binary/schema ordering can fail during rolling or manual release.
- Migration is not backward/forward compatible with live code.
- Startup accepts traffic before dependencies, schema, or config are ready.
- Config validation happens too late or fails open.
- Script targets production accidentally, lacks confirmation, or is not
  idempotent.
- Rollback path cannot handle already-applied schema/data changes.
- Health checks report healthy before core dependencies are usable.
- Release artifact activation is not atomic or leaves mixed versions.
- Generated files, migrations, contracts, or models can drift without a gate.

For each finding, include release sequence, exact failing order, blast radius,
detectability, rollback behavior, and minimal repair direction.
```
