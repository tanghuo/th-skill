---
name: sr-task-runner
description: Run a directory or batch of task markdown files through sr-task-loop one by one, with dependency ordering, checkpoint reviews, validation, and final integration review. Use for 批量执行小任务, run tasks, task runner, or looping over tasks created by sr-plan-split.
---

# SR Task Runner

## Goal

Execute a batch of task markdown files safely by repeatedly applying `sr-task-loop`.

This skill is the orchestration stage of the `sr-*` workflow:

```text
tasks directory
-> read overview and task DAG
-> choose next executable task
-> run sr-task-loop
-> checkpoint review after related task groups
-> repeat
-> final integration review
```

It is for large work that should not be done as one giant implementation pass.

## Trigger Rules

Use this skill when the user asks to execute a batch of task files or a task directory, for example:

- `sr-task-runner docs/foo-tasks`
- `循环执行这些小任务`
- `按任务目录一个个跑`
- `把这批 task md 执行完`
- `用 sr-task-runner 跑到没有 P0/P1`

Do not use this skill for:

- splitting a plan; use `sr-plan-split`
- one task only; use `sr-task-loop`
- pure review of a dirty worktree; use `sr-review` or `sr-worktree-review-fix-loop`
- unbounded autonomous operation without explicit user authorization and scope

## Required Companion Skills

Read:

- `/Users/chenxitang/.codex/skills/sr-task-loop/SKILL.md`
- `/Users/chenxitang/.codex/skills/sr-review/SKILL.md`
- `/Users/chenxitang/.codex/skills/sr-expert/SKILL.md` when Expert Strict Mode is requested

Use `sr-task-loop` as the unit of execution. This runner controls ordering, checkpoints, and final integration review.

## Inputs

Expected inputs:

- task directory or list of task markdown files
- optional scope, such as `all`, `next`, `range:3-5`, or a named phase
- optional stop condition, such as stop after first blocker, stop after N tasks, or run until all P1 tasks complete
- optional subagent authorization
- optional Expert Strict Mode when the user explicitly asks for `sr-expert`, external Expert, multi-model review, an independent/heterogeneous model review, or `Expert Strict Mode`

Default behavior:

- run the next pending task whose dependencies are completed
- stop at blockers that require user/product/external input
- after a meaningful group of tasks, run checkpoint review
- after all selected tasks complete, run final integration review
- when Expert Strict Mode is enabled, pass Expert Strict Gate into each `sr-task-loop` and add Expert cold review to checkpoint and final integration gates

## Runner State

Use the task files as the source of truth.

Status values:

- `pending`
- `in_progress`
- `blocked`
- `completed`

Do not maintain a parallel hidden checklist that disagrees with the files.

Before starting:

- read `00-overview.md` if present
- list all task files
- parse statuses and dependencies
- identify selected scope
- identify the next executable task

If status metadata is missing, infer conservatively and update files only when executing that task.

## Workflow

### 1. Inventory

Read the task directory with cheap local commands.

Build:

- task index
- dependency graph
- pending tasks
- blocked tasks
- completed tasks
- checkpoint boundaries from overview or natural phases

If the graph has cycles or missing dependencies, stop and report the plan defect. Do not guess an order that could corrupt the work.

### 2. Select Next Task

Choose the next task by this priority:

1. explicitly requested task
2. lowest-numbered pending task whose dependencies are completed
3. task in selected scope whose dependencies are completed
4. if none exists, report blockers

Do not skip a pending prerequisite merely because a later task looks easier.

### 3. Run Single-Task Loop

Apply `sr-task-loop` to the selected task.

If Expert Strict Mode is enabled, pass it into the single-task loop. The runner should not postpone task-local Expert findings until the end of the batch.

The runner should not dilute the single-task loop. Each task still needs:

- implementation
- validation
- spec review
- code review
- Expert Strict Gate when enabled
- repair
- task-file status update

If a task completes, refresh the inventory before selecting the next task.

If a task blocks, record it and stop unless:

- the user explicitly allowed continuing independent tasks
- there is a truly independent pending task with no dependency on the blocker

### 4. Checkpoint Review

Run a checkpoint review after:

- a phase completes
- two or three related tasks complete
- schema/domain/write-path tasks complete before read/display tasks
- external contract/client tasks complete before scheduler/backfill tasks
- the runner detects cross-task risk

Checkpoint review asks:

- Do completed tasks compose correctly?
- Did task boundaries introduce duplicated logic or naming drift?
- Are generated docs/schema/contracts still aligned?
- Are tests still passing beyond task-local scope?
- Has a later task become unnecessary, unsafe, or blocked?
- Are rollback and migration assumptions still valid?

If checkpoint review finds material issues:

- fix them directly when scoped and safe
- otherwise create or update a task file for the fix
- do not blindly continue into dependent tasks

When Expert Strict Mode is enabled, checkpoint review also includes an Expert cold workspace review over the completed checkpoint scope. Ask the Expert to start from `git status`, `git diff`, and the changed-file list, then focus on whether the completed tasks compose correctly. Accepted Expert findings that affect checkpoint composition, correctness, release safety, or any downstream task must be fixed directly when scoped and safe, or converted into blocking task files that complete before dependent work continues. Only findings explicitly accepted as backlog or residual risk may be deferred, and the checkpoint log must say why they do not block downstream work.

### 5. Final Integration Review

After selected tasks complete, perform a final review over the whole selected change.

For code work, review:

- git diff and changed files
- behavior against source plan
- data/schema/API/doc drift
- migrations and generated artifacts
- validation coverage
- rollback/release notes
- leftover TODOs or disabled paths

For plan/doc-only work, review:

- task completion consistency
- unresolved questions
- plan-to-task drift
- whether any task was marked completed without evidence

Say `未发现新的实质问题` only after this integration review finds no material issue.

When Expert Strict Mode is enabled, final integration review also requires an Expert cold workspace review over the whole selected change. Do not report the batch clean until both the Host final integration review and the latest Expert cold review have no accepted material findings.

Accepted Expert final-review findings must be fixed and re-reviewed before reporting the selected batch clean. If a finding is intentionally deferred, record it as backlog or residual risk only after deciding it does not invalidate the selected batch's correctness, release safety, or stated acceptance scope.

## Expert Strict Mode

Enable this mode only when the user explicitly asks for `sr-expert`, an external Expert, multi-model review, an independent/heterogeneous model review, or `Expert Strict Mode`.

Do not infer this mode merely from requests for a stricter runner, one-stop execution, more careful review, deeper local review, or a stronger host-only loop. Those requests should make the normal runner stricter without adding external Expert cost, authentication, repository exposure, or waiting time.

This mode makes the runner stricter without changing ownership:

- the runner remains responsible for dependency order, checkpoint boundaries, and final integration state
- each selected task is still executed by `sr-task-loop`
- `sr-task-loop` receives Expert Strict Gate and must not mark a task completed while its latest Expert cold review has accepted material findings
- checkpoint and final integration reviews add an Expert cold workspace review, not just Host self-review
- the Host Agent checks Expert findings against repo facts before accepting, fixing, blocking, or rejecting them

Prefer `sr-expert`'s Cold Workspace Review lane. The Expert should be read-only and should discover context from the repository, starting with `git status`, `git diff`, and changed files. The runner may provide only minimal constraints: selected task scope, checkpoint scope, excluded paths, read-only status, validation expectations, and time budget.

Do not provide the Host Agent's implementation narrative, suspected bugs, ranked findings, or "already checked" claims unless the user explicitly asks for a verification pass instead of independent review.

Loop shape:

```text
for each selected task:
  run sr-task-loop with Expert Strict Gate
  stop on blockers or accepted Expert findings that cannot be fixed locally

after checkpoint boundary:
  Host checkpoint review
  Expert cold checkpoint review
  fix accepted material findings before continuing dependent tasks
  convert dependency-affecting findings into blocking tasks, not backlog

after selected tasks complete:
  Host final integration review
  Expert cold final integration review
  fix accepted material findings and re-run affected gates until clean or blocked
```

If an Expert is unavailable, unauthenticated, unsafe to expose to the repository, or too slow for the user-approved scope, say so and continue only if the user accepts the degraded mode. Do not silently downgrade Expert Strict Mode to Host-only review.

## Agent-Assisted Execution

Default to using subagents as an execution accelerator when agent tools are available and tasks can be reviewed, investigated, or implemented independently.

Use them with these boundaries:

- use subagents for independent sidecar review or disjoint implementation tasks
- keep dependency ordering authoritative
- do not run two workers on overlapping files
- instruct workers that other agents may be editing and they must not revert unrelated changes
- review and integrate worker output before marking tasks complete

Skip subagents when the next task is tiny, dependency-blocking, or write scopes would overlap; when available tools cannot safely share the target workspace; or when the user explicitly asks for main-agent-only execution.

If subagents are unavailable or skipped, run the workflow locally in the main agent and say briefly why.

## Stop Conditions

Stop and report when:

- all selected tasks are completed and final integration review is clean
- if Expert Strict Mode is enabled, the latest Expert final integration review has no accepted material findings
- a blocker requires user/product/external input
- validation fails for a reason that cannot be fixed locally
- the task graph is inconsistent
- the user interrupts, redirects, or changes scope
- the same blocker repeats and no independent progress remains

Do not keep looping for wording polish, optional refactors, or non-material preferences.

## Output Shape

While running:

- short updates every meaningful step
- current task id
- validation/checkpoint status
- Expert Strict Mode pass status when enabled
- blocker status

Final answer:

- completed tasks
- blocked tasks, if any
- validation run
- checkpoint/final review result
- Expert Strict Mode result when enabled
- changed files or task files updated
- next recommended action

Avoid dumping every task detail into chat; the task files are the durable record.

## Batch Completion Log Guidance

When a checkpoint or final review changes the task set, update `00-overview.md` with:

- checkpoint date
- tasks completed since last checkpoint
- material integration findings
- fixes applied or new tasks created
- validation summary
- Expert Strict Mode result when enabled
- remaining blockers

## Quality Bar

A good run keeps the repo coherent after every task and never hides behind a large final review. Each task should be independently explainable, and the final integration review should be about composition, not discovering basic task misses for the first time.

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`: Codex is the canonical source — change it there first, then mirror to `~/.claude/` with the mappings in that file, and keep repo-specific names out of this global skill.
