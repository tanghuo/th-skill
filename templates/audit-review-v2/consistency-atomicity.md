# Transaction Boundary, Idempotency, And Partial Success Audit

```text
Audit business actions that should complete atomically across durable storage,
cache, RPC calls, message delivery, and in-memory state.

Starting points to customize:
- Multi-step write use cases: {{write_use_case_paths}}
- Async consumers and retry workers: {{job_or_consumer_paths}}
- Cache plus database double-write points: {{cache_and_db_paths}}

Transaction boundaries:
- Multiple database writes without a transaction.
- External RPC/cache/message calls inside a transaction.
- Durable write succeeds but cache/message/RPC fails without compensation.
- Notification emitted before commit.
- Long-running external calls while locks are held.

Idempotency:
- Duplicate requests or callbacks causing duplicate side effects.
- Idempotency key missing an important business dimension.
- Unique key, lock, or lease not matching the business invariant.
- Terminal state modified repeatedly.
- Optimistic-lock failure handled as success or ignored.
- Lock expiry allowing concurrent double writes.

Async work:
- Multiple workers can process the same object.
- Retry repeats non-idempotent side effects.
- Bad data is rescanned forever instead of repaired, skipped, or marked.
- Worker exit drops in-memory pending work.
- Callback or message disorder violates state assumptions.

For each finding, give the real entry and operation order, failure point,
partial-success state, missing idempotency boundary, business consequence, and
minimal repair direction.
```
