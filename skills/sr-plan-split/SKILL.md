---
name: sr-plan-split
description: Split a serious implementation plan, PRD, RFC, or large design doc into execution-ready task markdown files using sr-review standards. Use when the user asks to 拆任务, 拆小任务, split a plan, turn a方案md into tasks, or prepare a big plan for sr-task-runner/sr-task-loop execution.
---

# SR Plan Split

## Goal

Turn one large plan into a small set of execution-ready task documents.

This skill is the first stage of the `sr-*` workflow:

1. `sr-plan-split`: review and split the plan into tasks.
2. `sr-task-loop`: execute one task with implementation, validation, and review.
3. `sr-task-runner`: run a batch of task files through the single-task loop.

The output should reduce rework by making task boundaries, dependencies, acceptance criteria, validation commands, and stop conditions explicit before implementation begins.

This skill is inspired by two durable workflow ideas:

- Superpowers-style plan execution: read a written plan, review it critically, then execute small verifiable steps instead of improvising.
- ECC-style orchestration: decompose a plan into step units, attach the right review/verification chain to each step, and make each task self-contained enough for another agent or future session to run.

## Trigger Rules

Use this skill when the user asks to split or prepare a concrete non-trivial plan, for example:

- `sr-plan-split docs/foo.md`
- `把这个实施方案拆成小任务`
- `把完整方案 md 拆成 tasks`
- `拆一批可以循环执行的小任务`
- `按 sr-review 的方式拆任务`
- `给 sr-task-runner 准备任务目录`

Do not use this skill for:

- a tiny one-step edit
- ordinary code review
- vague brainstorming without a concrete plan artifact
- direct implementation requests where the user did not ask to split or plan
- task execution; use `sr-task-loop` or `sr-task-runner` for that

If the plan is missing, unreadable, or only exists as vague chat intent, ask for the plan path or produce a short outline only if the user explicitly wants one.

## Required Companion Skill

Before splitting a high-risk or non-trivial plan, read and apply:

- `/Users/chenxitang/.codex/skills/sr-review/SKILL.md`

Use `sr-review` as the review standard for the plan-read phase. This skill controls decomposition and task-file shape; `sr-review` controls scrutiny.

## Inputs

Expected inputs:

- plan path, pasted plan text, or named local artifact
- the `sr-split-ready` companion document, when one exists for this artifact
- optional output directory
- optional scope, such as one section, phase, or range
- optional execution constraints, such as no subagents, low-risk only, tests required, or keep P2 separate

If a `sr-split-ready` companion exists, its **Source Coverage Map is the authoritative enumeration of work to split**. Drive the split from the full Coverage Map, not from the First Wave list, the P0/P1 table, or the Split Scope summary alone — those are subsets. Every Coverage Map row must be accounted for in the output (as a task, an acceptance condition on a named task, a backlog preservation row with its original detail, or an explicit out-of-scope/no-task note with reason). Silently dropping a Coverage Map row is a P0/P1 splitting blocker.

A one-line overview entry is not enough for deferred work. If the Coverage Map contains `backlog`, `dedup-to-existing-plan`, or non-primary `split-across` targets that are not assigned to an active task, create a backlog preservation artifact such as `99-backlog.md` or `backlog/00-overview.md`. That artifact must carry forward the source item, disposition, target bucket, preserved detail, validation-first status, and future split condition for each deferred row.

Backlog preservation must keep validation uncertainty intact. If the source row is `validation-first`, medium confidence, suspected, owner-confirmation dependent, or says to validate/prove/confirm before repair, the backlog row's `Validation-first?` value must be `yes`; its detail and future split condition must describe validation before repair, not a predetermined fix.

`merged-into` is not deferred by default. It means the source detail is folded into the named target. If the target is an active task, the detail must appear in that task's context, implementation notes, acceptance criteria, or review checklist. Only when the merge target is itself a deferred backlog bucket should the row go to the backlog preservation artifact.

`split-across` creates one reconciliation obligation per named target. Do not mark the source row covered just because its primary target is covered. Each primary and secondary target must have its own landing place, such as a task file, a named acceptance criterion, or a backlog preservation row.

If a source target is renamed, collapsed, split, or reclassified during planning, the Coverage Reconciliation table must preserve the original source target and state the equivalent landing place. Do not rely on readers to infer that `Task H`, `Task 06`, and `schema guard` refer to the same obligation.

Default output directory:

- If the plan is `docs/foo.md`, write tasks under `docs/foo-tasks/`.
- If the user names a directory, use that directory.
- If the artifact is pasted and no repo path is obvious, propose a directory and ask only if writing would be risky.

## Workflow

### 1. Freeze the Plan

Read the plan artifact and record:

- source path or artifact id
- current git status when the plan is local
- plan title and stated goal
- sections that define P1/P2, scope, non-goals, and validation

If the user supplied both pasted text and a file path, identify which one is authoritative. When cheap, compare them and report drift.

### 2. Plan Executability Review

Before creating tasks, review the plan for blockers.

Treat these as P0/P1 blockers for splitting:

- unclear source of truth for data, APIs, schemas, money, permissions, or time windows
- contradictory scope or incompatible P1/P2 boundaries
- missing ownership between services
- missing migration or rollout order for stateful changes
- no way to validate correctness
- unresolved product decision that affects implementation shape
- hidden dependency on an unbuilt external system without a stub/fallback plan
- rollback impossible or undefined for a risky financial/security/data migration

If P0/P1 blockers exist:

- stop before writing task files unless the user explicitly asks for a draft despite blockers
- lead with the blockers
- propose exact plan amendments needed before splitting

If only minor gaps exist:

- continue splitting
- carry the gaps into task `Open Questions` or `Residual Risks`

### 3. Identify Task Units

Prefer task units that are independently understandable and verifiable.

Good task units:

- change one layer or one vertical slice with a clear acceptance test
- have a small, named write scope
- can be reviewed with line-level or artifact-level evidence
- can fail independently without corrupting later tasks
- leave the repo in a coherent state

Bad task units:

- "implement everything"
- "clean up related code"
- "wire all downstream behavior"
- mix schema, business rules, UI, external API, and backfill without a checkpoint
- require future tasks to make tests pass unless explicitly marked as a scaffold step

Use this splitting priority:

1. prerequisites and source-of-truth contracts
2. schema/domain/data model
3. repository or storage primitives
4. core write paths
5. read/display paths
6. jobs, schedulers, external clients
7. correction/backfill/repair paths
8. integration, rollout, observability, and docs

Keep P2/nice-to-have work in separate optional tasks. Do not mix it into P1 tasks.

When a Source Coverage Map is present, honor each disposition:

- `first-wave` becomes a task.
- `validation-first` becomes a task unless the user explicitly asks to defer it; if deferred, it must appear in the backlog preservation artifact as validation-first work.
- `split-across` produces a task for the primary plus a task, named acceptance condition, or backlog preservation row for every secondary target. Do not collapse secondaries into the primary.
- `merged-into` must be carried into the named target. If that target is an active task, the preserved detail must appear inside that task; if the target is a backlog bucket, preserve it in the backlog artifact.
- `backlog` and `dedup-to-existing-plan` must be carried into the backlog preservation artifact with their preserved details, not only summarized in `00-overview.md`.
- `covered-by-existing-work` and `out-of-scope` are noted as no-task-needed with their cited evidence or reason.

Do not invent new scope beyond the map, and do not omit any row from it.

### 4. Define Dependencies and Order

For every task, identify:

- dependencies by task id
- whether it can run in parallel with others
- whether it is a blocking prerequisite
- whether it requires product or external-service confirmation

Prefer a DAG over a flat list. If a task cannot be made safe without an unresolved decision, mark it `blocked` rather than burying the risk.

The dependency DAG is authoritative. Prefer deriving `Parallel with` from the DAG instead of hand-maintaining broad lists. If explicit `Parallel with` fields are written, they must be:

- mutually exclusive with direct or transitive dependencies
- symmetric between both task files
- consistent with runner constraints such as product confirmation, external service access, or shared mutable files

If a task is intentionally not parallel despite no DAG dependency, record the reason as a runner constraint instead of silently omitting it from one side's `Parallel with` list.

When one task prepares a hook, placeholder, interface, generated artifact slot, config surface, or CI/Makefile entry that another task implements or consumes, add a `Handoff Contract` to the relevant task files. The contract must state:

- what this task creates
- what this task consumes from other tasks
- whether consumed outputs are hard dependencies or soft handoffs
- fallback behavior when a soft handoff producer is not complete
- what this task must not implement
- which later task completes the handoff, if any

This prevents two tasks from both claiming ownership of the same implementation detail.

Do not turn every handoff into a hard DAG dependency. If a task can proceed safely before its producer task finishes, record a soft handoff instead. If no safe fallback exists, the producer must be a hard dependency.

Gate tasks must be typed clearly. If a task is named or described as a final, integration, release, merge, or batch-completion gate, it must depend on every task whose output it gates. If it only checks a subset, name it as a partial/local/CI gate instead and explicitly state what it does not gate. Do not combine "final gate" language with a partial DAG.

### 5. Write Task Files

Create one markdown file per task unless the user asks for one combined file.

Recommended naming:

```text
tasks/
  00-overview.md
  01-contract-and-boundary.md
  02-schema-and-domain.md
  03-repository-queries.md
```

Every task file must include:

```markdown
# Task NN: <short title>

Status: pending
Source plan: <path or artifact id>
Depends on: <task ids or none>
Parallel with: <task ids or none>
Risk: low|medium|high

## Goal

One or two sentences describing the exact outcome.

## Scope

Files, modules, schemas, docs, or APIs likely owned by this task.

## Out of Scope

Explicit exclusions. Include P2 or future work here.

## Context

Only the plan facts and repo facts needed to execute this task without rereading the full plan.

Orientation anchors: the key existing files to read first, as `path` plus the relevant symbol (function/type/section) — no line numbers, they go stale. List read-first anchors even when this task will not modify them; this is distinct from `Scope`, which lists what the task owns or writes.

## Implementation Notes

Specific constraints, invariants, edge cases, and local patterns to preserve.

## Acceptance Criteria

- Verifiable criterion.
- Verifiable criterion.

## Validation

- Command or manual check.
- Expected signal.

## Review Checklist

- Spec review question.
- Code quality or artifact quality question.
- Regression risk question.

## Open Questions

- None, or exact question with owner.

## Handoff Contract

- This task creates: <interfaces, hooks, placeholders, generated slots, or none>.
- This task consumes: <task outputs it depends on, or none>.
- Hard dependencies: <task ids that must finish first, or none>.
- Soft handoffs: <producer task, consumed artifact, and later finalization, or none>.
- Fallback if producer is incomplete: <safe default/degraded behavior, or n/a>.
- This task must not: <neighboring implementation scope>.
- Completed by: <this task or later task id>.

## Completion Log

Leave empty until `sr-task-loop` updates it.
```

Also create `00-overview.md` with:

- task index table
- DAG/order
- link to `99-backlog.md` or the chosen backlog preservation artifact, when one exists
- global invariants
- global validation plan
- integration review checkpoints
- rollback or release gates
- unresolved questions

If the overview names any final/integration/release gate, state the gated task set explicitly. If the gate is partial, state the excluded tasks and why they are not gated.

When deferred Coverage Map rows exist, also create a backlog preservation file, normally `99-backlog.md`, with:

```markdown
# Backlog Preservation

Status: preserved
Source plan: <path or artifact id>

## Purpose

Carry forward deferred, deduped, and deferred secondary Coverage Map rows without turning them into first-wave implementation work.

## Backlog Ledger

| Source item | Disposition | Target bucket | Detail preserved | Validation-first? | Future split condition |
|---|---|---|---|---|---|
| C-4 | backlog | BL-OWNER-RENEW | distinguish renew err from !ok; short retry on Redis jitter | yes | Split only after refreshing evidence around owner lease renewal behavior. |

## Bucket Notes

- `BL-...`: source items grouped here, shared constraints, known dependencies, and any existing planning docs to reuse.
```

The backlog file is not permission to execute deferred work. It is a preservation record so future splitting starts from the same source detail instead of a thin overview label.

When `split-across` rows exist, include a reconciliation table in `00-overview.md` or the backlog preservation artifact:

```markdown
## Coverage Reconciliation

| Source item | Target role | Target | Landing place |
|---|---|---|---|
| D12-2 | primary | SR-P1-G | Task 04 acceptance criteria |
| D12-2 | secondary | Backlog-Layering | `99-backlog.md` Backlog Ledger |
```

Every named target in every `split-across` row must appear exactly once in this table.

If a target was renamed or reclassified, include the original source target in the Target column or in the Landing place note, for example:

```markdown
| B-4 | primary | source: Task H schema guard | Task 06 schema smoke plus Task 09 gate |
```

### 6. Add Runner Hints

In `00-overview.md`, include a `Runner Instructions` section for `sr-task-runner`:

- how to choose the next task
- when to stop
- when to run local integration review
- final review requirements
- subagent usage constraints, including any user request to disable or limit subagents

Assume `sr-task-runner` may use subagents for independent review or disjoint execution unless the user explicitly disables them. Record any constraints that affect safe delegation, such as overlapping files, hidden context, credentials, environment limits, or tasks that must stay main-agent-only.

### 7. Validate the Split

Before finishing, re-read the generated task files and check:

- each task has a concrete acceptance criterion
- every dependency points to an existing task
- explicit `Parallel with` fields, if present, are symmetric and contain no direct or transitive dependency pairs; intentional non-parallel pairs without a dependency have a stated runner constraint
- any final/integration/release/merge/batch-completion gate depends on every task it claims to gate; partial gates are named as partial/local/CI gates and list excluded tasks
- no task secretly contains multiple unrelated changes
- P1/P2 boundaries survived the split
- validation is realistic in the current repo
- high-risk tasks have rollback or review gates
- if a Source Coverage Map was provided, every row is accounted for in the output (task, named acceptance condition, backlog preservation row with detail, or no-task note with reason) and no row was silently dropped; `split-across` secondaries each survived as their own task, named acceptance, or backlog preservation row
- every named `split-across` target is reconciled separately; covering the primary target does not cover secondary targets
- renamed, collapsed, split, or reclassified source targets in Coverage Reconciliation preserve the original target and state the equivalent landing place
- every `merged-into` row lands in the named target's task detail when the target is active, or in the backlog preservation artifact when the target is deferred
- if any Coverage Map row is deferred, deduped, or secondary-only without an active task target, the backlog preservation artifact exists and carries the original load-bearing detail; a bare bucket label in `00-overview.md` is not sufficient
- backlog preservation rows keep validation uncertainty intact: source validation-first/medium-confidence/suspected/owner-confirmation rows are marked `Validation-first? yes` and describe validation before repair
- when a backlog preservation artifact exists, `00-overview.md` links to it so runners know where deferred detail lives
- tasks that share ownership of a hook, generated slot, config surface, CI/Makefile entry, or cross-task artifact include a `Handoff Contract` that separates creator, consumer, non-goals, and completing task
- if a task consumes another task's output but does not list that task as a hard dependency, it declares a soft handoff with fallback behavior; without a safe fallback, the producer must be a hard dependency

If you edited files, report the created paths and the remaining blockers.

## Output Shape

When only reviewing/splitting conceptually, answer with:

- whether the plan is executable
- P0/P1 blockers, if any
- proposed task list
- recommended next command or skill

When writing task files, answer with:

- output directory
- task count
- any blockers carried forward
- suggested next skill invocation, usually `sr-task-runner <tasks-dir>`

Keep the final response concise; the task files carry the detail.

## Quality Bar

A good split makes a future agent less likely to:

- skip a dependency
- implement the wrong source of truth
- claim done without tests
- mix unrelated changes
- forget downstream rebuilds or generated artifacts
- lose the distinction between product decision, implementation fact, and residual risk

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`: Codex is the canonical source — change it there first, then mirror to `~/.claude/` with the mappings in that file, and keep repo-specific names out of this global skill.
