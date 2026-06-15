---
name: redis-key-discipline
description: Use when designing or refactoring Redis keys so names stay readable, consistent, and cluster-aware, with only the slot-sharing token inside `{}` and the semantic path outside it.
---

# Redis Key Discipline

## Goal

Keep Redis keys readable, stable, and cluster-aware.
Use hash tags only for the slot-sharing part of the key, not for the whole semantic path.

## Core principles

- Put only the slot/grouping token inside `{}`.
- Put the action or sub-resource path outside the hash tag, separated by `:`.
- Prefer `{domain}:action:...` over `{domain_action}:...` when the action is not the slot identity.
- Keep naming consistent with nearby keys in the same codebase.
- Do not extract one-off key helpers unless they carry real shared meaning.

## Preferred pattern

Preferred:

```text
{gift}:send_request:<userID>:<requestID>
{room}:enter:<roomID>
{room_membership}:<userID>
```

Avoid:

```text
{gift_send_request}:<userID>:<requestID>
```

## Decision rule

Pick the format that makes these questions obvious:

1. What domain does this key belong to?
2. What operation or sub-resource is this?
3. Which part actually needs to share a Redis cluster slot?

If these answers differ, only the slot-sharing token belongs inside `{}`.
