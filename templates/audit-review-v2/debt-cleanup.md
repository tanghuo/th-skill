# Debt Cleanup Audit

```text
Audit dead code, duplicated logic, low-value abstraction, naming/semantic drift,
and cleanup opportunities that carry real maintenance risk.

Starting points to customize:
- Core business packages: {{core_package_paths}}
- Helper, wrapper, and abstraction packages: {{helper_paths}}
- Script/tooling directories: {{tool_paths}}
- Recently refactored areas: {{recent_refactor_paths}}

Check:
- Unused production functions, files, scripts, migrations, config, or docs that
  can mislead future work.
- Duplicate logic for the same business rule, key format, state transition,
  amount conversion, or authorization check.
- Interfaces or wrappers with one production implementation and no real runtime
  boundary.
- Test-only seams leaking into production structure.
- Naming drift where multiple terms refer to the same concept or one term means
  multiple concepts.
- Comments or docs that contradict current behavior.
- Compatibility code whose migration window has ended.

Do not report pure style preferences. For each finding, show the real confusion
or risk, references proving drift/duplication/deadness, and minimal cleanup.
```
