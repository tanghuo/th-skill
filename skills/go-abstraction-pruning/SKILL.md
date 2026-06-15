---
name: go-abstraction-pruning
description: Use when simplifying Go code that has accumulated thin wrappers, test-driven fallbacks, low-value interfaces, or naming drift from historical refactors.
---

# Go Abstraction Pruning

## Goal

Remove abstraction layers that do not earn their keep.
Keep runtime design explicit, small, and honest.

## When to use

Use this skill when:

- a package has many wrappers that mostly forward to another function
- interfaces exist without a meaningful runtime boundary
- constructors hide fallback implementations or convenience wiring
- test-only behavior leaked into production code
- names reflect historical implementation shapes instead of current responsibilities
- the code feels padded with layers that are individually explainable but collectively unnecessary

## Core principles

- Every abstraction should justify itself in runtime semantics, not aesthetics.
- A layer that only forwards, renames, or hides setup cost is usually negative-value.
- Prefer explicit dependencies over hidden fallback assembly.
- Remove old transition layers once the real architecture is in place.
- Tests may need helpers; production code does not need to carry those helpers for them.
- Historical names should not freeze historical architecture in place.

## Common low-value abstractions

- exported wrappers that only call a private helper with the same contract
- small local interfaces with one production implementation and no real runtime substitution need
- fallback implementations left in production after tests or migration no longer need them there
- constructors that auto-create substitute dependencies for convenience
- helper layers added during a refactor and never removed after the migration finished
- old type or file names preserved after the responsibility changed

## Working approach

1. Identify the real runtime boundary and the real caller-visible contract.
2. Mark each extra layer as one of: required boundary, temporary migration layer, or convenience wrapper.
3. Delete convenience wrappers first.
4. Move test-only convenience into `_test.go` helpers.
5. Collapse duplicate implementation surfaces so one concept has one primary implementation point.
6. Rename types, fields, and files so the surviving structure reads naturally.
7. Re-run tests and confirm the design is smaller and still explicit.

## Decision rule

Keep an abstraction only if at least one is true:

- it represents a real runtime boundary
- it changes the contract in a way callers can observe
- it expresses ownership or coordination semantics the underlying type does not
- it isolates unstable external behavior
- removing it would force duplication of meaningful business rules

If none are true, prefer deleting it.

## Review checklist

1. What runtime meaning does this layer add?
2. What breaks semantically if this layer is deleted?
3. Is this abstraction here for production behavior or for developer convenience?
4. Could a test helper replace this production fallback?
5. Are there two names or two layers carrying one concept?
6. Is this code still needed, or is it just leftover migration scaffolding?

## Expected outcomes

Applied well, this skill should produce:

- fewer wrapper layers
- fewer test-driven production seams
- smaller constructors with explicit dependencies
- names that match current responsibilities
- code that is easier to read because there is less to mentally subtract
