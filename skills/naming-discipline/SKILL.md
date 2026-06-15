---
name: naming-discipline
description: Use when reviewing or refactoring names so identifiers, helper names, Redis keys, and wire-level terms follow one consistent semantic shape instead of drifting by local convenience.
---

# Naming Discipline

## Goal

Keep naming consistent across the codebase.
Names should expose domain, action, and ownership clearly, instead of mixing multiple ideas into one token.

## Core principles

- Prefer one stable naming shape per concept family.
- Name by semantic ownership, not by local convenience.
- Keep domain and action separate when they are different pieces of meaning.
- Match nearby conventions unless there is a strong reason to introduce a new shape.
- Do not invent a new naming style for one isolated case.
- Rename the surrounding identifiers and file names when a type’s role changes; do not leave historical names that describe an old responsibility.
- Keep exported type names, held field names, and file names aligned when they refer to the same concept.

## Database naming

- Inside the database, prefer internal relation keys such as `gift_action_id` over business-facing ids such as `action_id` when the relationship is a strong row-to-row association.
- Keep business/public ids for wire contracts and external tracing only when they carry distinct business meaning beyond existing request ids or order numbers.
- Do not mix internal surrogate keys and business ids under the same column name family. If a column stores a row relation, name it like `<domain>_id` and make it the internal numeric key.

## Redis keys

- Put only the slot-sharing token inside `{}`.
- Put the action or sub-resource path outside the hash tag, separated by `:`.
- Prefer `{gift}:send_request:...` over `{gift_send_request}:...` when the action is not the slot identity.

## Decision rule

Choose names that make these questions obvious:

1. What domain does this belong to?
2. What action, sub-resource, or stronger contract is this?
3. Who owns the meaning of this name?
4. Does this name match the surrounding naming pattern?

If the answers are being compressed into one awkward token, the naming is probably doing too much.

## Refactoring rule

When renaming for correctness:

- update the type name
- update the main holder field names
- update constructor names where needed
- update file names when the old file name preserves outdated meaning

Do not stop halfway with a corrected type inside a stale file or stale field name.

## Review checklist

1. Does the type name describe the current responsibility, not the historical one?
2. Do the holder field names and constructor names match the same concept family?
3. Does the file name still point to an outdated role such as `registry.go` after the type became a manager or coordinator?
4. Are we preserving an old name only because renaming the rest feels inconvenient?
