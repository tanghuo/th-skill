# State Consistency Audit

```text
Audit state machines, business invariants, and drift between durable truth and
derived projections.

Starting points to customize:
- State objects and transitions: {{state_machine_paths}}
- Durable truth tables or event logs: {{truth_source_paths}}
- Cache/projection/update jobs: {{projection_paths}}
- Reconciliation jobs: {{reconciliation_paths}}

Check:
- Illegal transitions, skipped terminal states, or reopened terminal states.
- Multiple writers that do not share one invariant.
- Projection fields treated as truth.
- Cache or search index drift without reconciliation.
- State transitions that are not monotonic where business semantics require it.
- Missing version, timestamp, or compare-and-swap guards on concurrent updates.
- Historical sessions or records incorrectly treated as active.

For each finding, show the invariant, real entry path, transition sequence,
truth source vs projection behavior, user-visible or data impact, and minimal
repair direction.
```
