# Performance And Capacity Audit

```text
Audit hot-path performance, SQL/index behavior, pagination, fanout, and
unbounded work.

Starting points to customize:
- High-traffic entries: {{hot_entry_paths}}
- Expensive list/search/query endpoints: {{query_paths}}
- Batch jobs and reconciliation scans: {{batch_paths}}
- Schema and index definitions: {{schema_paths}}

Check:
- N+1 database, cache, or RPC calls on user-visible paths.
- Full table scan, filesort, temporary table, or missing composite index on hot
  predicates.
- OFFSET deep pagination where keyset pagination is needed.
- Unbounded list, map, set, stream, or fanout operation.
- Cold-cache behavior does many serial external calls.
- Batch job lacks bounded page size, cursor, checkpoint, or resumability.
- Query predicate order does not match available index shape.
- Locks or transactions span large scans.

For each finding, include the entry, data-size growth dimension, query or loop
shape, existing index/protection if any, expected failure mode, and minimal
repair direction.
```
