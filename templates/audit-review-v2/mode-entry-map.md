# High-Risk Entry Map Mode

> Standalone mode. Do not concatenate `_base.md`.

```text
Do not report bugs. Identify high-risk entries and core state objects, then
write or refresh `.local/review/entry-map.md`.

If an entry map already exists, do an incremental refresh based on git changes
instead of rebuilding from scratch.

Enumerate:
1. Public HTTP, RPC, WebSocket, CLI, callback, webhook, and admin entries.
2. Jobs, workers, schedulers, consumers, and repair scripts.
3. Destructive tools, data scripts, seed scripts, migration helpers, and release
   scripts.
4. Core durable tables/collections/events and their primary writers.
5. Core cache keys, queues, streams, locks, and projections.
6. Core state fields, transitions, and reconciliation paths.
7. Money, entitlement, permission, ownership, or externally visible state paths.
8. External dependencies and config items that affect runtime behavior.

For each entry, record:
- File path and function/handler/job name.
- Trigger mechanism.
- Core state touched.
- Suggested audit topic.

Write the generation date and base commit at the top of the map.
```
