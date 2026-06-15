# Error Boundary Audit

```text
Audit swallowed errors, unsafe nil or zero-value fallbacks, and boundary failure
semantics.

Starting points to customize:
- External RPC/HTTP/cache/database clients: {{external_boundary_paths}}
- Decoding/binding/parsing paths: {{decode_paths}}
- Batch jobs and per-item loops: {{batch_paths}}
- Helper functions that collapse errors into bool/zero values: {{helper_paths}}

Check:
- Error is logged then ignored while success state is returned.
- Error collapses into nil/zero/empty value that is a valid business value.
- Type assertion, map lookup, pointer dereference, or slice access lacks a
  boundary check where input is untrusted.
- Per-item batch errors prevent later repair visibility or cause infinite retry.
- Dead-letter, quarantine, manual-review, or retry cap is missing where required.
- Fallback data is used as authoritative data.
- Fail-open behavior exists in authorization, payment, settlement, release, or
  destructive tooling paths.

For each finding, include the boundary, exact error path, resulting false
success/fallback, impact, and minimal repair direction.
```
