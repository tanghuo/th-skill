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
-> repair
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
- record changed files, validation run, review result, and residual risks

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

Validation layers, from narrow to broad:

- pure unit tests for new helpers
- package tests for touched behavior
- integration tests or generated checks when contracts changed
- static checks when the repo normally requires them
- manual SQL/doc/schema diff checks when runtime tests are not available

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

### 7. Update Task File

When the task-local loop is clean:

- set `Status: completed`
- append a completion log entry with:
  - date/time when useful
  - changed files
  - validation commands and outcomes
  - spec review outcome
  - code review outcome
  - residual risks or skipped validation

If blocked:

- set `Status: blocked`
- append blocker details and required owner/input

### 8. Stop Condition

Stop when:

- all acceptance criteria are satisfied
- validation passed or skipped validation is non-material and disclosed
- spec review finds no material task-local issue
- code review finds no material task-local issue
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

Final answer:

- task completed or blocked
- changed files
- validation result
- review result
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
- Notes:
  - ...
```
