# sr-subthread (EXPERIMENTAL design draft — NOT an active skill)

> Status: design draft only. This is **not** a live skill and `sr-task-runner` does
> **not** depend on it. Do not act on it as a mechanism until C0 (capability probe)
> passes. See "Adoption gates" at the bottom.
>
> Idea: an opt-in companion to `sr-task-runner`. When a task clears a conservative
> complexity threshold, dispatch it to an isolated, resumable sub-thread (own worktree
> + durable handoff) instead of running it inline or as an ordinary subagent.

## 1. Trigger logic

A sub-thread opens only when **both** preconditions hold **and** at least one isolation
benefit applies.

Preconditions (all required):

- the task is self-contained with a clear output contract;
- acceptance criteria are explicit.

Isolation benefit (at least one):

- **context offload** — spans multiple feature domains / enough steps to blow the main context;
- **high-risk worktree isolation** — a write stream landing on `schema-or-migration`,
  `money-or-settlement`, or a cross-layer contract that needs an isolated worktree and
  independent proof;
- **explicit adversarial review** — a separate reviewer thread is wanted to downgrade
  unsupported conclusions.

Do NOT open (fall back to inline or an ordinary subagent):

- the task is small, local, or mechanically obvious;
- scope is not frozen / boundaries unclear (parallelize independence, not uncertainty);
- write scope overlaps an already-running sub-thread;
- the user asked for main-agent-only execution.

> Note: self-contained + clear acceptance is a **precondition**, not a sufficient
> trigger. The real switch is one of the three isolation benefits.

## 2. Ordinary subagent vs sub-thread

`sr-task-loop` / `sr-task-runner` already default to using subagents as an accelerator.
A sub-thread is a heavier, distinct mechanism — keep the two separate so the runner knows
whether to dispatch or stay inline.

| Dimension | Ordinary subagent (existing default) | Sub-thread (this draft) |
|---|---|---|
| Lifecycle | short-lived, ephemeral | persistent, resumable |
| State | in-context, lost on end | handoff file + worktree, durable |
| Workspace | shares the main worktree | own git worktree/branch |
| Output | a final message | 5-section handoff + real commits |
| Fits | bounded read-only sidecar, disjoint quick impl | context offload / high-risk isolated write / adversarial review |
| Default | ON when tools are available | **OFF** unless this companion is explicitly loaded **and** a trigger matches |

### 5-section handoff schema

A sub-thread returns a compact handoff (≈50–100 lines):

1. **Output contract** — what it delivers and the scope boundary;
2. **Proof** — what validation ran, results, and proof freshness (when produced, whether stale);
3. **Diff / commit refs** — exact changed files plus commit or patch references;
4. **Acceptance status** — each acceptance criterion as pass / fail / not-covered;
5. **Blockers** — open questions, decisions needed from the main line, anything outside the allowed write scope.

## 3. Runner integration cost

Hosting this companion is not a one-line addition. The runner must add at least three
things:

1. **Recognition** — detect whether the optional companion is loaded;
2. **Selection order** — small/obvious → inline; bounded sidecar → ordinary subagent;
   trigger matched → sub-thread;
3. **Acceptance order** — read the sub-thread's handoff/proof/diff first, re-read its
   session only when that is missing/stale/contradictory; never mark `completed` without
   evidence.

Without all three, the option exists on paper but has no execution entry point.

## 4. Codex capability matrix (do not write mechanism as fact until verified)

| Capability | Used for | Codex status | Claude mapping |
|---|---|---|---|
| create a bounded goal/objective | task scope | **VERIFIED**: `goals_1.sqlite` present, create_goal usable | Agent prompt scope |
| resumable independent sub-thread | durable worker | **UNVERIFIED** — confirm the Codex primitive before writing it as a mechanism | partial: Agent + SendMessage continues a spawned agent |
| bind a worktree/branch to a thread | write isolation | **UNVERIFIED** | Agent `isolation: "worktree"` |
| durable handoff location | recovery | repo file (both) | repo file (both) |
| who verifies | controller | runner (both) | runner (both) |

The two UNVERIFIED rows must be tested before being written as an executable mechanism;
until then they are design analogies only.

## Adoption gates

- **C0 (capability probe)** — minimal controlled test of the two UNVERIFIED primitives
  (resumable sub-thread, worktree binding): can it start, resume, and yield handoff+diff?
  C0 may depend directly on these primitives, since verifying them is its purpose.
- **C1 (dogfood)** — only after C0 passes, run one real task through the trigger logic.
  Select the dogfood task at C1 start by the criteria above (frozen scope, existing
  validation framework, write scope disjoint from any running subagent/runner). Do not
  pre-name it; room-core→application migration or a multi-domain audit are candidate
  examples, not commitments.
- Only after C1 decide whether to promote this to a real skill and wire the runner
  integration in §3.
