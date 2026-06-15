# Audit Review Template v2

This template initializes a repo-local `.local/review/` audit prompt library.
It is meant to be copied into a repository and then customized with that
repository's real entry points, domain semantics, and run history.

## Install Into A Repository

```bash
mkdir -p .local/review
cp -R /path/to/th-skill/templates/audit-review-v2/. .local/review/
```

After copying, edit these sections before the first audit:

- `README.md`: file index, recommended rhythm, and run history.
- `_base.md`: project-specific semantics and known non-bugs.
- Topic files: replace `{{...}}` placeholders with real package paths, schema
  files, service names, and domain state objects.

## Usage

- `/audit <topic>` when the global `audit` skill is installed.
- Manual mode: concatenate `_base.md` and one topic file.
- `mode-*` files are standalone and must not be concatenated with `_base.md`.

Run one topic at a time, ideally in a clean session. If you limit the scope,
prepend `Only scan <path>` before the topic prompt.

## File Index

### Base

| File | Purpose |
|---|---|
| `_base.md` | Audit discipline, severity, false-positive filtering, project semantics, and output format. |

### Topics

| File | Purpose |
|---|---|
| `money-settlement.md` | Money precision, overflow, over-deduction, settlement idempotency, and accounting date semantics. |
| `consistency-atomicity.md` | Transaction boundaries, idempotency, partial success states, and async retry semantics. |
| `consistency-state.md` | State machines, business invariants, and durable/projection drift. |
| `realtime-messaging.md` | Long-lived connection lifecycle, delivery semantics, and online/member state. |
| `security-authz.md` | Entry authentication and object-level authorization. |
| `concurrency-resource.md` | Races, connection maps, goroutine/resource leaks, and lifecycle cleanup. |
| `error-boundary.md` | Swallowed errors, nil/zero-value boundaries, and unsafe fallback behavior. |
| `resilience-overload.md` | Timeout, retry, degradation, rate limiting, backpressure, and resource exhaustion. |
| `contract-alignment.md` | API, field semantics, time units, schema, and model alignment. |
| `perf-capacity.md` | SQL/index performance, pagination, unbounded loops, and hot-path capacity. |
| `security-exposure.md` | Secret leakage, privacy exposure, log exposure, and supply-chain risk. |
| `release-ops.md` | Release compatibility, migrations, scripts, startup safety, and rollback hazards. |
| `observability.md` | Debuggability gaps discovered by incident-walkthrough style audits. |
| `test-effectiveness.md` | Whether tests and CI gates can catch important regressions. |
| `debt-cleanup.md` | Dead code, duplicated logic, low-value abstractions, and drift cleanup. |

### Standalone Modes

| File | Purpose |
|---|---|
| `mode-change-review.md` | Incremental review for a diff, PR, or recent commit. |
| `mode-over-implementation.md` | Checks whether a change exceeds the minimal sufficient solution. |
| `mode-entry-map.md` | Generates or refreshes a high-risk entry map before deeper audits. |
| `mode-architecture-review.md` | Periodic architecture review using a local ledger and evidence-driven rotation. |

## Recommended Rhythm

- First pass: run `mode-entry-map`, then the first three to five highest-risk topics.
- Pull request: run `mode-change-review`; optionally follow with one focused topic.
- Pre-release: run `release-ops`, then `security-exposure`.
- Monthly: run two or three topics selected from recent changes and stale run history.
- Architecture: run `mode-architecture-review` every one to two months.

## Run History

Update this table after each audit. Keep it repo-local; do not sync a project's
run history back into this template.

| Topic | Last Run | Findings (P0/P1/P2/P3) | Notes |
|---|---|---|---|
| money-settlement | Not run | - | - |
| consistency-atomicity | Not run | - | - |
| consistency-state | Not run | - | - |
| realtime-messaging | Not run | - | - |
| security-authz | Not run | - | - |
| concurrency-resource | Not run | - | - |
| error-boundary | Not run | - | - |
| resilience-overload | Not run | - | - |
| contract-alignment | Not run | - | - |
| perf-capacity | Not run | - | - |
| security-exposure | Not run | - | - |
| release-ops | Not run | - | - |
| observability | Not run | - | - |
| test-effectiveness | Not run | - | - |
| debt-cleanup | Not run | - | - |
| mode-change-review | Not run | - | - |
| mode-over-implementation | Not run | - | - |
| mode-entry-map | Not run | - | - |
| mode-architecture-review | Not run | - | - |
