# Money & Settlement Audit

> Highest priority for financial-risk systems. Checks precision, overflow,
> over-deduction, settlement reruns, and accounting-date semantics.

```text
Audit numeric correctness and rerun safety in money, balances, gifts, points,
revenue shares, salaries, payouts, credits, or any value-bearing workflow.

Starting points to customize:
- Settlement or payout jobs: {{settlement_job_paths}}
- Value write paths: {{money_write_paths}}
- Schema and field definitions: {{schema_paths}}
- External payment/wallet/provider callbacks: {{callback_paths}}

Precision and types:
- Whether float participates in calculation or storage.
- Whether minor units, display units, points, coins, or credits are mixed across
  tables and interfaces.
- Whether database column types can contain realistic maximum business values.
- Whether revenue share, discount, multiplier, and rounding direction are
  explicit and consistent.
- Whether split rounding reconciles back to the total amount.

Overflow and negative values:
- Whether count * unit price, accumulated totals, or cross-period totals can
  overflow.
- Whether negative amount/count values can enter calculations.
- Whether balance deduction checks available funds and remains atomic under
  concurrency.

Settlement rerun and accounting semantics:
- Whether rerunnable jobs are truly idempotent: duplicate insert protection,
  unique keys, replace/upsert semantics, and non-accumulating recomputation.
- Whether RowsAffected semantics are interpreted correctly for the configured
  database driver.
- Whether accounting date uses the business timezone.
- Whether interval boundaries avoid duplicate or missed inclusion.
- Whether overlapping rerun windows are safe.

For each finding, include the amount field and calculation path, concrete
triggering input, financial direction, and minimal repair direction.
```
