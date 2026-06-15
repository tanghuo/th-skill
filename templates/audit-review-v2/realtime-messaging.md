# Realtime Messaging And Long-Lived Connection Audit

```text
Audit WebSocket, realtime messaging, session delivery, online state, and room or
channel membership semantics.

Starting points to customize:
- Connection and protocol handlers: {{connection_paths}}
- Dispatch/broadcast paths: {{dispatch_paths}}
- Online/member state storage: {{presence_paths}}
- Replay/resume/offline-message paths: {{resume_or_replay_paths}}

Connection lifecycle:
- Failed authentication leaves a usable connection.
- Disconnect, timeout, kick, close, or logout leaves stale subscriptions.
- Heartbeat does not detect dead connections.
- Reconnect restores stale membership or misses required state.
- Multi-device/session replacement is incomplete.

Delivery semantics:
- Actual guarantee differs from business expectation: at-most-once,
  at-least-once, ordering, replay, or deduplication.
- Missing sequence, dedupe key, or idempotent client contract.
- Offline or replay delivery duplicates, drops, or reorders messages.
- Partial broadcast failure is invisible or leaves inconsistent state.

Online and membership state:
- Fact source is unclear or projections are treated as truth.
- Close/end events do not clean up subscriptions.
- A new logical session can inherit old subscriptions or presence state.

For each finding, include the involved path, wrong semantic assumption, trigger
condition, user-visible consequence, and minimal repair direction.
```
