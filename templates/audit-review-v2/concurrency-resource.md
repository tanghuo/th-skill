# Concurrency And Resource Lifecycle Audit

```text
Audit races, goroutine lifecycle, connection/resource cleanup, and shared-state
safety.

Starting points to customize:
- Shared in-memory state and connection maps: {{shared_state_paths}}
- Goroutine producers and workers: {{goroutine_paths}}
- Stream, channel, queue, or fanout paths: {{queue_paths}}
- Resource acquisition and cleanup paths: {{resource_paths}}

Check:
- Shared maps, slices, counters, or structs accessed without a consistent lock.
- Lock order inversion or lock held across blocking RPC/IO.
- Goroutines can leak after request, connection, context, or service shutdown.
- Channels can block forever or drop silently.
- Timers, tickers, rows, bodies, transactions, locks, leases, subscriptions, or
  file handles are not closed/released.
- Cleanup is asymmetric between success, failure, timeout, and cancellation.
- Backpressure or queue overflow corrupts state or hides important failure.

For each finding, include the concurrent actors, synchronization boundary,
trigger interleaving, leaked/corrupted resource, impact, and minimal repair
direction.
```
