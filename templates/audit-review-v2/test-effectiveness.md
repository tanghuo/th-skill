# Test Effectiveness Audit

```text
Audit whether tests and CI gates catch important regressions rather than merely
increasing coverage numbers.

Starting points to customize:
- Critical domain workflows: {{critical_workflow_paths}}
- Existing unit/integration/e2e tests: {{test_paths}}
- CI and release gates: {{ci_paths}}
- Recent bugs or high-risk changes: {{recent_bug_or_change_paths}}

Check:
- Critical invariants have no direct regression test.
- Tests mock away the boundary where the bug would occur.
- Tests assert implementation details but not business outcomes.
- Integration tests exist but are not in CI or require undocumented setup.
- Flaky, skipped, or environment-dependent tests hide real failures.
- Golden-path tests miss duplicate request, retry, concurrency, rollback, or
  partial-failure cases.
- CI does not run generated-code checks, schema drift checks, migration checks,
  race checks, or contract checks where needed.
- Existing tests would not have caught a recent real bug.

For each finding, include the missed invariant, current test/gate behavior, why
it would not catch the regression, and the smallest useful test or gate.
```
