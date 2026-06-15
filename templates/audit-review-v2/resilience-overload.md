# Resilience And Overload Audit

```text
Audit timeout, retry, degradation, rate limiting, backpressure, and resource
exhaustion behavior.

Starting points to customize:
- External service calls: {{external_call_paths}}
- Hot public entries and fanout paths: {{hot_entry_paths}}
- Queue, worker, stream, or scheduler paths: {{worker_paths}}
- Rate limit or quota enforcement: {{limit_paths}}

Check:
- Missing timeout or context propagation across network, DB, cache, or queue
  calls.
- Retry without cap, jitter, idempotency, or error classification.
- Retry storm or synchronized schedule can amplify an outage.
- Degradation hides critical failure or violates business correctness.
- Queue growth is unbounded or overflow is invisible.
- Rate limit key is too broad, too narrow, caller-controlled, or absent.
- Bulkhead/isolation missing between high-risk workloads and core traffic.
- Startup or dependency outage leaves the service accepting traffic it cannot
  handle.

For each finding, include the overload source, trigger path, amplification
mechanism, user/business impact, observability signal, and minimal repair
direction.
```
