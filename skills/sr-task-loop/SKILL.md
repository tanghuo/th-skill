---
name: sr-task-loop
description: "Execute one task markdown file through a disciplined implementation loop: read context, implement the minimum viable change, validate, spec-review, code-review, fix, and update the task. Use for 单任务闭环, task loop, or one task from an sr-plan-split task directory."
---

# SR Task Loop

## Goal

Run one small task from `pending` to `completed` using a repeatable implementation-review loop.

This is the core unit of the `sr-*` workflow:

```text
read task
-> freeze scope
-> implement minimum coherent change
-> validate
-> spec review
-> code review
-> repair Host findings and validate
-> expert strict gate when requested or passed by runner
-> repair accepted Expert findings and validate
-> Host re-review repair diff
-> Expert re-review until clean or blocked
-> repeat until no material task-local issues remain
-> update task status and completion log
```

The loop deliberately separates:

- `spec review`: did we satisfy the task and plan?
- `code review`: did the implementation introduce bugs, bad boundaries, or maintainability risk?

## Trigger Rules

Use this skill when the user asks to execute one task file or one task unit, for example:

- `sr-task-loop docs/foo-tasks/03-repository-queries.md`
- `跑这个小任务闭环`
- `执行 Task 4，按小任务循环`
- `用 sr-task-loop 做这个 task`

Do not use this skill for:

- splitting a large plan; use `sr-plan-split`
- running a whole task directory; use `sr-task-runner`
- review-only requests unless the user asks for a loop
- unrelated opportunistic refactors outside the task scope

If more than one task is named, either ask which one to run or switch to `sr-task-runner` when the user clearly wants batch execution.

## Required Companion Skills

Read `/Users/chenxitang/.codex/skills/sr-review/SKILL.md` before the review phases.

Also use any domain-specific skill that clearly applies to the touched code, such as Go abstraction, database discipline, naming discipline, or fail-fast wiring. Keep domain skills subordinate to the task scope.

When the user explicitly asks for `sr-expert`, an external Expert, multi-model review, an independent/heterogeneous model review, `Expert Strict Gate`, or when `sr-task-runner` passes Expert Strict Mode into this task, also read `/Users/chenxitang/.codex/skills/sr-expert/SKILL.md` and enable the Expert Strict Gate below.

## Inputs

Expected task file fields:

- `Status`
- `Source plan`
- `Depends on`
- `Goal`
- `Scope`
- `Out of Scope`
- `Context`
- `Implementation Notes`
- `Acceptance Criteria`
- `Validation`
- `Review Checklist`
- `Open Questions`
- `Completion Log`

Optional execution modifiers:

- Expert Strict Gate enabled by the user or by `sr-task-runner`

If fields are missing, reconstruct enough from the task and source plan to proceed. If the missing field creates a material ambiguity, stop and ask or mark the task blocked.

## Status Rules

Allowed status values:

- `pending`
- `in_progress`
- `blocked`
- `completed`

Before editing implementation files:

- mark the task `in_progress` unless the user asked not to edit task files
- record a short start entry in `Completion Log`

After success:

- mark `completed`
- record changed files, validation run, review result, Expert Strict Gate result when enabled, and residual risks

When blocked:

- mark `blocked`
- record the exact blocker and what input or external change is needed

Do not mark `completed` if validation was impossible and the missing validation is material to the acceptance criteria.

## Workflow

### 1. Read and Freeze

Read the task file and any referenced overview/source plan sections needed for the task.

Freeze:

- task id and path
- acceptance criteria
- declared scope and out-of-scope items
- dependencies
- current git status
- relevant existing code paths

If dependencies are not completed:

- do not start unless the task is explicitly independent or the user overrides
- report the dependency gap

If the worktree is dirty:

- identify whether dirty changes are related
- never revert unrelated user changes
- work with related changes when possible

### 2. Clarify Only Real Blockers

Ask the user only when:

- acceptance criteria contradict each other
- a product decision affects money/security/data correctness
- a required external contract is unknowable locally
- proceeding would likely create throwaway work

Otherwise make conservative repo-aligned assumptions and proceed.

### 3. Implement Minimum Coherent Change

Keep edits inside task scope.

Implementation rules:

- prefer existing project patterns
- keep public API changes minimal
- avoid abstractions that exist only for tests
- avoid unrelated cleanup
- preserve generated-file conventions
- update docs, schema, generated clients, or migrations when the task explicitly owns that surface
- if an unexpected adjacent bug blocks the task, fix it only when it is necessary and tightly scoped

For manual edits, use `apply_patch`.

### 4. Validate

Run the validation listed in the task.

If the task's validation is too broad or stale:

- run the narrowest command that directly checks the changed behavior
- explain the substitution in the completion log

Select a verification tier by what the change actually touches. There are two axes, not one linear gradient.

Scope gradient (narrow to broad; a higher level includes the lower levels' evidence):

- `docs-only` — docs, comments, non-executed text. Evidence: internal consistency, plus a docs build if one exists. Skip runtime, datastore, and tests.
- `code-unit` — pure in-process logic with no external IO. Evidence: the narrowest unit/package test for the changed behavior. Skip the full suite and integration.
- `integration` — code that crosses a real boundary (datastore, cache, queue, RPC, socket, filesystem). Evidence: a focused test exercising that boundary; bootstrap only what that test needs. Skip unrelated packages and full-environment runs.

Risk gates (orthogonal; when the change touches one, stack its evidence on top of the applicable scope level — they do not imply each other and do not imply `integration`):

- `schema-or-migration` — schema/DDL or data migration. Evidence: apply against an isolated store and check migration ordering and forward/backward shape. Never run against shared or real data.
- `money-or-settlement` — amounts, balances, settlement, payout, or idempotency/rerun-sensitive state. Evidence: re-derive the amount unit and the timezone day boundary, and prove idempotency and rerun/retry semantics on isolated data.
- `ops-or-production` — production data, ops actions, or irreversible external effects. Stay read-only first; mutate only after explicit user authorization. Never mutate silently.

Example: a pure in-process amount calculation stays at `code-unit` scope but must add `money-or-settlement` evidence; do not force `integration` evidence onto it.

Baseline evidence (independent of tier, always applies):

- static/lint/generated checks the repo normally requires;
- when the target behavior cannot run in the current environment, fall back to manual SQL/doc/schema-diff structural checks and record in the completion log why it degraded — do not silently skip validation.

This table is a generic framework only. Concrete commands, table/column names, money-unit and timezone rules, and environment bootstrap are not written here; take them in fixed priority order from the task's `Validation` field first, then the repo profile as a reusable default, then project memory as a supplementary hint only. Never hard-code repo specifics into this framework.

If a validation command fails:

- determine whether the failure is caused by the change, pre-existing state, or environment restriction
- fix task-caused failures
- do not hide environment failures; record them

### 5. Spec Review

Review the result against the task and source plan.

Ask:

- Is every acceptance criterion satisfied?
- Did we stay inside scope?
- Did we preserve out-of-scope boundaries?
- Did we use the correct source of truth?
- Did we update every artifact promised by the task?
- Did we leave a future task impossible or misleading?

If spec review finds material gaps, repair and re-run relevant validation.

### 6. Code Review

Review the implementation as a code reviewer.

Lead with material findings:

- behavioral regression
- data loss or wrong persistence
- broken API/schema/doc contract
- concurrency, transaction, idempotency, retry, or scheduling issue
- authorization/security issue
- time-zone, money-unit, or boundary bug
- missing generated artifact or migration
- tests that assert the wrong behavior

Treat as non-material unless it affects execution:

- naming taste
- optional example coverage
- formatting handled by tools
- broad refactor preference

If code review finds material issues, repair and re-run validation.

### 7. Expert Strict Gate

Enable this gate when the user explicitly asks for `sr-expert`, an external Expert, multi-model review, an independent/heterogeneous model review, `Expert Strict Gate`, or when `sr-task-runner` passes Expert Strict Mode into this task.

This gate is task-local. It is not a replacement for the runner's checkpoint or final integration review.

Use `sr-expert`'s Cold Workspace Review lane by default when the Expert can safely read the repository or a scoped worker copy. Ask the Expert to review the current task result read-only, starting from `git status`, `git diff`, and the changed-file list, then to build its own context from repo facts.

Host context to the Expert should be minimal:

- task file path and frozen task id
- frozen task scope and acceptance criteria only when needed to identify the task target
- read-only constraint
- excluded paths or forbidden actions, if any
- validation expectations or time budget, if relevant

Do not send the Host Agent's implementation summary, suspected bugs, ranked findings, or "already checked" claims unless the user explicitly asks for verification rather than independent review.

Loop rule:

1. Run Host spec review and code review first.
2. Fix Host material findings and re-run relevant validation.
3. Run the Expert cold workspace review.
4. Check each Expert finding against repo facts.
5. Repair accepted material Expert findings and re-run relevant validation.
6. Re-run Host spec review and code review over the Expert-driven repair diff before relying on the previous Host review result.
7. Re-run the Expert cold workspace review after any Host repair caused by Expert findings and after the Host re-review is clean.

Do not mark the task `completed` while the latest Expert cold workspace review still has accepted material findings. If the same accepted Expert finding repeats after two repair attempts, or the correct behavior cannot be inferred locally, mark the task blocked with the exact reason.

If the Expert is unavailable, unauthenticated, unsafe to expose to the repository, or too slow for the user-approved scope, say so and continue only if the user accepts the degraded mode. Do not silently downgrade the Expert Strict Gate to Host-only review.

### 8. Update Task File

When the task-local loop is clean:

- set `Status: completed`
- append a completion log entry with:
  - date/time when useful
  - changed files
  - validation commands and outcomes
  - spec review outcome
  - code review outcome
  - Expert Strict Gate outcome, when enabled
  - residual risks or skipped validation

If blocked:

- set `Status: blocked`
- append blocker details and required owner/input

### 9. Stop Condition

Stop when:

- all acceptance criteria are satisfied
- validation passed or skipped validation is non-material and disclosed
- spec review finds no material task-local issue
- code review finds no material task-local issue
- if the Expert Strict Gate is enabled, the latest Expert cold workspace review has no accepted material finding
- task file is updated

Say `未发现新的实质问题` for the task-local review. Do not claim the whole feature is perfect.

## Agent-Assisted Execution

Default to using subagents as an execution accelerator when agent tools are available and the task has meaningful sidecar work, risky results to review, or disjoint implementation scope.

Use them with these boundaries:

- keep the immediate blocking task local
- delegate bounded sidecar work only
- prefer clean-context read-only review for risky task results
- for worker agents, assign disjoint file ownership
- tell workers not to revert unrelated changes and to list changed files

Skip subagents when the task is tiny, local, and mechanically obvious; when worker startup cost would exceed the work; when write scopes would overlap; or when the user explicitly asks for main-agent-only execution.

The main agent owns integration, validation, and final task status.

## Output Shape

During execution, provide short progress updates:

- task frozen
- implementation area
- validation running
- review finding/fix status
- if the Expert Strict Gate is enabled, Expert pass status or skip reason

Final answer:

- task completed or blocked
- changed files
- validation result
- review result
- Expert Strict Gate result when enabled
- next suggested task if obvious

Keep details in the task file; keep the chat response high-signal.

## Completion Log Template

```markdown
### YYYY-MM-DD HH:MM

- Status: completed|blocked
- Changed files:
  - path
- Validation:
  - command: result
- Spec review: no material gaps | gaps fixed | blocked by ...
- Code review: no material issues | issues fixed | residual risk ...
- Expert strict gate: not enabled | no accepted material findings | findings fixed | blocked by ...
- Notes:
  - ...
```

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`: Codex is the canonical source — change it there first, then mirror to `~/.claude/` with the mappings in that file, and keep repo-specific names out of this global skill.
