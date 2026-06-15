---
name: go-api-surface-discipline
description: Use when refactoring Go APIs to keep public method sets small, make contract-strengthening methods earn their place, and avoid wrapper layers added only for symmetry or style.
---

# Go API Surface Discipline

## Goal

Keep Go API surfaces small, direct, and semantically honest.
Do not add exported methods, wrapper pairs, or forwarding layers unless they express a real contract difference that callers need.

## When to use

Use this skill when:

- a refactor introduces `GetX` and `RequireX`, `LoadX` and `MustX`, or similar paired methods
- an exported method only forwards to a private helper
- a new API is being added mainly to make naming feel complete or symmetrical
- reviewers are debating whether a wrapper adds value or just another hop
- a package starts growing thin exported helpers that mirror internal functions
- the user explicitly asks to avoid over-encapsulation or over-design

## Core principles

- Keep the public API smaller than the implementation surface.
- Do not add an exported method just because a naming pair looks tidy.
- Add sibling methods only when they expose a real contract difference.
- Prefer one exported method with a clear contract over a family of near-identical wrappers.
- A `RequireX` method should strengthen behavior, not merely rename the same behavior.
- If a private helper already owns the behavior, an exported wrapper should do the minimum additional semantic work.
- Do not keep both an exported helper and a private helper when they have the same contract and one only forwards to the other.
- Symmetry is not a sufficient reason to expand an API.
- When a user asks to avoid over-encapsulation, treat minimal API growth as the top design constraint.

## Working approach

1. Identify the contract callers actually need.
2. Check whether an existing private helper already provides the behavior.
3. Ask whether the proposed exported method changes the contract in a way callers can observe.
4. If the answer is no, do not add the method.
5. If the answer is yes, make the wrapper express only that extra contract.
6. Keep internal helpers private unless multiple external callers truly need the weaker form.
7. Re-check whether the new API reduces caller confusion more than it increases package surface.
8. Collapse duplicate implementation layers when the exported and private forms carry the same semantics.

## Decision rule

Add a new exported API only if at least one of these is true:

- callers need a different success or failure contract
- callers need a different ownership boundary or abstraction boundary
- callers need a stable semantic capability that is clearer than the helper beneath it
- multiple call sites would otherwise duplicate the same semantic strengthening

If none are true, keep the helper private or reuse the existing exported method.

When choosing between an exported wrapper and a private helper:

- keep only one implementation surface when both do the same thing
- prefer the exported method when callers outside the package need the behavior
- prefer the private helper when no external caller needs it

## Preferred patterns

### 1. Strengthen contract in the exported wrapper

Preferred:

```go
func (s *Service) RequireRoomStateSnapshot(ctx context.Context, roomID int64) (*domain.RoomStateSnapshot, error) {
    snapshot, err := s.loadRoomStateSnapshot(ctx, roomID)
    if err != nil {
        return nil, err
    }
    if snapshot == nil {
        return nil, xerr.New(xerr.CodeNotFound, "room not found")
    }
    return snapshot, nil
}
```

This wrapper earns its place because it strengthens the contract to “must exist”.

### 2. Do not create a pair without a weaker public contract

Avoid:

```go
func (s *Service) GetRoomStateSnapshot(ctx context.Context, roomID int64) (*domain.RoomStateSnapshot, error) {
    return s.loadRoomStateSnapshot(ctx, roomID)
}

func (s *Service) RequireRoomStateSnapshot(ctx context.Context, roomID int64) (*domain.RoomStateSnapshot, error) {
    return s.GetRoomStateSnapshot(ctx, roomID)
}
```

If `GetRoomStateSnapshot` does not allow a weaker contract such as `nil, nil`, it usually adds no value.

### 3. Keep private helpers as the implementation surface

Preferred:

```go
func (s *Service) RequireThing(ctx context.Context, id int64) (*Thing, error) {
    thing, err := s.loadThing(ctx, id)
    if err != nil {
        return nil, err
    }
    if thing == nil {
        return nil, errThingNotFound
    }
    return thing, nil
}
```

The private helper stays reusable inside the package.
The exported method exposes the stronger contract.

### 4. Do not expand API surface for naming symmetry alone

Avoid introducing `GetX` only because `RequireX` sounds lonely.
Avoid introducing `LoadX` only because another type uses `LoadY`.
Repeated naming shapes are useful only when the contracts also repeat.

### 5. Prefer the smallest reversible API

When unsure, add the smallest exported method that solves the current caller need.
You can always add a weaker sibling later if a real use case appears.
Removing a needless exported method later is harder.

### 6. Remove thin same-contract wrappers

Avoid:

```go
func CloneRoomStateSnapshot(snapshot *RoomStateSnapshot) *RoomStateSnapshot {
    return cloneRoomStateSnapshot(snapshot)
}
```

If `CloneRoomStateSnapshot` is the API callers need, put the implementation there.
Do not keep a second helper unless it carries separate internal meaning.

## Good API additions

These usually earn their place:

- `GetX` returning `nil, nil` and `RequireX` converting absence into `not found`
- an exported method that moves caller-owned semantic strengthening onto the owning type
- a small wrapper that enforces a business contract the private helper does not guarantee
- a method that clearly separates lookup from validation or requirement

## Bad API additions

These are often negative-value additions:

- an exported `GetX` that only forwards to `loadX` with identical semantics
- a `RequireX` that does nothing except rename an already-required helper
- a sibling API added only because another package has a similarly named pair
- a public wrapper that exists to make the package “feel complete”
- a new API that adds an extra hop but no new caller-facing meaning
- a public `X` and private `x` pair where one only forwards to the other with identical behavior

## Review guidance

When reviewing:

- ask what caller-visible contract changed
- ask whether the weaker form is truly needed by external callers
- push back on exported forwarding methods with identical semantics
- prefer comments like “this adds API surface without adding contract” over vague concerns about style
- treat user requests for less encapsulation as a concrete design constraint, not a preference to ignore

## Review checklist

1. Does this exported API add a caller-visible contract, or is it only forwarding?
2. If there is both an exported and private helper, why do both need to exist?
3. Can the implementation live directly on the single method callers actually use?
4. Is this API smaller and clearer than simply deleting one layer?

## Expected outcomes

Applied well, this skill should produce:

- smaller public Go APIs
- fewer meaningless wrapper layers
- clearer `Get` versus `Require` distinctions
- less over-design for symmetry
- exported methods whose names and contracts actually match
