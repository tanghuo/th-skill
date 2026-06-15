# Authentication And Authorization Audit

```text
Audit public entries and object-level authorization.

Starting points to customize:
- Public HTTP/RPC/WebSocket/callback entries: {{entry_paths}}
- Auth middleware and token/session parsing: {{auth_paths}}
- Object lookup and ownership checks: {{object_authz_paths}}
- Admin/operator/tooling entries: {{admin_or_tool_paths}}

Check:
- Entry without authentication where authentication is required.
- Authentication is present but object ownership/tenant/scope is not checked.
- Caller-controlled user, tenant, role, or owner fields are trusted.
- Permission check happens after a side effect.
- Internal endpoint is reachable externally or lacks shared-secret/mTLS/network
  boundary assumptions.
- Debug, seed, repair, or destructive tool can run in production unexpectedly.
- Authorization helper fails open on lookup errors, nil objects, or zero values.

For each finding, include the public or internal entry path, identity source,
object being protected, missing or wrong check, exploit sequence, impact, and
minimal repair direction.
```
