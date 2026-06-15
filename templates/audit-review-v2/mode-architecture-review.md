# Architecture Review Mode

> Standalone mode. Do not concatenate `_base.md`.

```text
Run a periodic architecture review using evidence from the current repository.
This mode is for structural risks and architectural drift, not ordinary code
style or small local bugs.

Maintain a local ledger at `.local/review/arch-reports/_ledger.md` and write
dated reports under `.local/review/arch-reports/`.

Dimensions:
A. Ownership and boundaries: module ownership, write ownership, dependency
   direction, internal vs external contracts.
B. State and consistency: truth sources, projections, reconciliation,
   idempotency, and lifecycle transitions.
C. Operability and evolution: release safety, config boundaries, observability,
   migrations, rollback, and cleanup.
D. Simplicity and fit: abstraction cost, accidental frameworks, over-wide APIs,
   and mechanisms that exceed the product/runtime reality.

Process:
1. Read the current ledger if present.
2. Choose the requested dimension A/B/C/D, or rotate to the stalest/highest-risk
   dimension if none is requested.
3. Use the entry map if present; otherwise build a lightweight map first.
4. Inspect real code and docs before reporting.
5. Record decisions, risks, and follow-up actions in the ledger.

Report format:

## Scope
- Dimension:
- Evidence read:

## Architecture Findings
### [Priority] Title
- Evidence:
- Architectural risk:
- Why this matters now:
- Minimal action:

## Ledger Updates
- Decisions confirmed:
- Decisions changed:
- Follow-ups:
```
