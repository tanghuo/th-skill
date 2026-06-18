---
name: sr-task-runner
description: Run a directory or batch of task markdown files through sr-task-loop with dependency-aware scheduling, safe parallelism, checkpoint reviews, validation, and final integration review. Use for 批量执行小任务, run tasks, task runner, or looping over tasks created by sr-plan-split.
---

# SR Task Runner

## Goal

Execute a batch of task markdown files safely and quickly by repeatedly applying `sr-task-loop` through a dependency-aware scheduler.

This skill is the orchestration stage of the `sr-*` workflow:

```text
tasks directory
-> read overview and task DAG
-> compute the current schedulable ready set
-> choose the fastest safe execution shape
-> run one or more sr-task-loop units, using isolated workers when safe
-> integrate, validate, and update task files
-> integration review for completed ready-set waves; checkpoint review at checkpoint boundaries
-> repeat
-> final integration review
```

It is for large work that should not be done as one giant implementation pass.

Default posture: maximize safe throughput. The runner should automatically decide when to parallelize exploration, review, or implementation, and fall back to serial execution only when dependency, checkpoint, isolation, write-scope, validation, or recovery constraints make parallelism unsafe. Do not ask the user to choose serial vs parallel or to classify task safety; only surface blockers that genuinely require user/product/external input.

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
- optional agent-assisted execution preference; if omitted, the runner may still use safe read-only sidecars and isolated worker lanes when the host provides suitable tools
- optional Expert Strict Mode when the user explicitly asks for `sr-expert`, external Expert, multi-model review, an independent/heterogeneous model review, or `Expert Strict Mode`

Default behavior:

- compute all pending selected tasks whose dependencies are completed
- choose the fastest safe execution shape for that ready set: serial task loop, parallel read-only exploration/review, or isolated-worker implementation
- stop at blockers that require user/product/external input
- after each completed ready-set wave, run integration review when it gates downstream work or crosses shared risk
- at checkpoint boundaries, run full checkpoint review
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
- compute the current ready set
- identify checkpoint boundaries, task-file parallelism constraints, and shared write-risk hints

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
- ready tasks for the current schedulable wave
- checkpoint boundaries from overview or natural phases
- declared write scopes and likely shared files for ready tasks
- explicit parallelism constraints from task files or overview

If the graph has cycles or missing dependencies, stop and report the plan defect. Do not guess an order that could corrupt the work.

### 2. Plan Ready Set

Build the ready set from selected `pending` tasks whose dependencies are completed.

Choose the execution shape by this priority:

1. explicitly requested task or range, respecting its dependencies and checkpoint boundaries, still executed in the fastest safe shape within the requested scope when parallelism is safe; do not pull in unrequested tasks just to fill a parallel batch
2. all ready tasks in the current schedulable wave that do not cross a checkpoint boundary
3. the lowest-numbered ready task only when parallelism is unsafe, or when the ready set contains a single task; never merely because serial is simpler
4. if none exists, report blockers

Do not skip a pending prerequisite merely because a later task looks easier.

Scheduling is per-prerequisite, not whole-layer by default. A downstream task becomes ready as soon as all of its own prerequisites are integrated, validated, reviewed, and marked `completed` by the Host Agent in the task files. Worker-reported "done" is not dependency completion.

A layer-wide integration review is a barrier only for tasks that depend on the layer as a whole, such as checkpoint, final integration, release-gate, or explicitly grouped tasks. It must not block downstream tasks whose specific prerequisites are already Host-completed and do not cross that barrier.

Checkpoint boundaries are hard barriers. A ready set must not cross a checkpoint boundary, and a checkpoint task or checkpoint review must run alone before downstream tasks are scheduled.

A checkpoint task forms its own single-task layer.

### 3. Choose Safe Throughput Mode

The runner owns the parallelism decision. The user should not have to know which tasks are safe to parallelize.

For the current ready set, classify each task by:

- dependency layer
- checkpoint boundary
- declared scope and likely actual write scope
- shared files, generated artifacts, migrations, schemas, module files, config fixtures, test helpers, task files, and overview/index files
- validation commands and external resources
- rollback/recovery path
- whether an isolated worker workspace or branch can be created
- whether the task needs to create or mutate shared sequentially numbered or global-namespace artifacts that require Host pre-allocation or Host-owned integration

Execution modes:

- `serial-write`: run one `sr-task-loop` in the Host Workspace.
- `parallel-readonly`: use agents only for exploration, risk discovery, spec review, or code review; no worker writes.
- `isolated-parallel-write`: run disjoint tasks in separate Worker Workspaces or branches, then integrate one worker result at a time in the Host Workspace.

Note: `isolated-parallel-write` parallelizes implementation. Validation may still serialize through the Host Workspace when validation-resource isolation is unevidenced.

Default to the fastest safe mode:

- If the ready set has one task, run `serial-write` unless sidecar review or exploration materially reduces risk.
- If multiple ready tasks exist, isolated Worker Workspaces are available, write scopes are disjoint by the best available evidence, and validation resources are isolated or evidenced non-contended, use `isolated-parallel-write` for tasks that can be independently implemented and reviewed without crossing checkpoint boundaries. When disjointness or validation-resource isolation is not yet evidenced, run `parallel-readonly` exploration first, then re-decide or keep validation serial.
- If write scope is unclear, likely shared, or isolation is unavailable, use `parallel-readonly` to discover scope and risks while the Host serializes writes.
- If a task file or overview says tasks should be sequential in the same worktree, obey it. Parallel writing is allowed only by using isolated Worker Workspaces and later Host integration.

Hard safety rules:

- Never run parallel writers in the same worktree. Declared non-overlapping scope is a planning hint, not a guarantee.
- Choose `isolated-parallel-write` only when write scopes are disjoint by the best available evidence. Write-scope evidence comes from explicit task or overview declarations plus `parallel-readonly` exploration of likely touched files; when either source is missing or inconclusive, treat the scope as possibly overlapping. Use `parallel-readonly` exploration first when scopes are not yet evidenced. Enforce real disjointness after launch through Host diff inspection; when overlap or integration conflict is detected, reject the conflicting worker result and re-run that task through `serial-write`.
- Do not run parallel workers whose validation contends on the same non-isolatable external resource, such as a shared database, fixed port, singleton service, or rate-limited API. When a parallel task's validation resource isolation is undeclared or unknown, treat it as contended; run that task's validation serially through `serial-write` or use `parallel-readonly` until isolation is evidenced.
- Worker agents must not write shared overview, task-index, dependency, checkpoint, or runner-state files. The Host Agent alone updates shared task state.
- Worker agents must not allocate global identifiers or create unassigned shared sequentially numbered or global-namespace artifacts, such as migrations, schema versions, generated registries, or generated indexes. If such an artifact is required, the Host Agent must either keep the task in `serial-write` or pre-allocate an isolated identifier, slot, or file before launch; the worker may fill only that assigned surface.
- Host merged-workspace validation must explicitly check namespace and identifier collisions, not only textual diff conflicts, when any worker touched generated, schema, migration, registry, or index surfaces.
- Worker agents must not mark tasks `completed`. They report changed files, validation, findings, blockers, and a diff or branch/worktree reference; the Host marks completion only after integration and review.
- Give each isolated worker its own build/test cache and generated-output discipline when the language or tooling can write shared cache state.
- Keep parallel writer fan-out small enough for the Host Agent to review each diff seriously. Batch broad ready sets into smaller waves when needed.
- Record in-flight assignments durably in task logs, overview, or runner notes before launching workers: task id, worker id or workspace, worker output reference such as branch, commit, or diff path, allowed scope, validation expectation, and integration status.
- On restart or recovery, reconcile the durable in-flight record against task-file state before scheduling more work. The only completion source of truth is a Host-written `completed` status in the task file. Treat any worker output whose task is not marked `completed` in the task file as not completed, regardless of whether the in-flight record says `merged`, `integrated`, or `merged-pending-validation`; re-validate and re-review it before use.
- Host integration into the Host Workspace must be atomic or reversible, such as a single merge commit, stash-revertible patch, or other recoverable application. On restart, if a task is not Host-completed in the task file, discard any partial merge of that task from the Host Workspace before re-validating; never re-validate a possibly half-merged workspace.

### 4. Run Task Loops Or Worker Lanes

Apply `sr-task-loop` to each selected task according to the chosen mode.

If Expert Strict Mode is enabled, pass it into each selected task or worker lane. The runner should not postpone task-local Expert findings until the end of the batch.

The runner should not dilute the single-task loop. Each task still needs:

- implementation
- validation
- spec review
- code review
- Expert Strict Gate when enabled
- repair
- Host-owned task-file status update

For `serial-write`, the Host Agent runs the full `sr-task-loop` and updates the task file.

For `parallel-readonly`, agents may inspect code, task files, tests, contracts, and validation paths, but they must not edit files. Run read-only exploration on a consistent snapshot, or before the Host writes the files whose ordering the exploration is meant to inform, so stale findings are not fed back into the task loop. The Host integrates their findings into the serial task loop, defaulting to the lowest-numbered ready task first unless the findings reveal a blocker or safer ordering.

For `isolated-parallel-write`, each worker receives one task or a bounded implementation slice, a Worker Workspace or branch, allowed write scope, forbidden shared files, validation expectations, and instructions not to mark task completion. The Host Agent then:

- inspects the worker's actual diff before accepting it
- rejects or repairs out-of-scope changes
- integrates one worker result at a time into the Host Workspace
- updates the durable in-flight record as `merged-pending-validation` or `rejected` after merge/rejection
- runs relevant validation on the merged Host Workspace, not only in the worker workspace
- runs Host spec and code review before marking the task completed
- updates task files and shared overview/index files itself
- updates the durable in-flight record to `completed` only after validation, Host spec/code review, and the task-file `completed` status all succeed

If a task or worker blocks, record it and continue only with ready tasks that are truly independent of the blocker, do not cross the same checkpoint, and do not require the blocked task's integration.

After each completed task or worker integration, refresh inventory before scheduling downstream work. Run ready-set integration review when the completed wave gates downstream work or crosses shared risk. At checkpoint boundaries, run full checkpoint review before downstream work continues.

### 5. Ready-Set And Checkpoint Review

Run a ready-set integration review after a completed wave when it gates downstream work, crosses shared risk, or owns a grouped handoff. This is a focused composition check before scheduling dependent work.

Run a full checkpoint review after:

- a phase completes
- an overview-defined or inventory-derived related task group completes
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

### 6. Final Integration Review

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

Default to using agents as an execution accelerator when the scheduler finds safe parallel work. The runner, not the user, should decide the fastest safe mode from the DAG, task constraints, workspace isolation, and validation risk.

Use them with these boundaries:

- use agents for independent sidecar review, read-only exploration, or isolated-worker implementation tasks
- keep dependency ordering authoritative
- do not run two writers in the same worktree
- instruct workers that other agents may be editing and they must not revert unrelated changes
- review and integrate worker output before marking tasks complete
- prefer isolated Worker Workspaces or branches for parallel implementation
- keep shared task state, overview files, and dependency metadata under Host ownership

Skip implementation agents when the ready task is tiny, dependency-blocking, crosses a checkpoint, cannot be isolated, or write scope is too entangled for useful delegation. In those cases, consider read-only agents for scope discovery or review while the Host serializes writes.

If agents are unavailable or skipped, run the workflow locally in the main agent and say briefly why. If the runner falls back to serial execution after considering a multi-task ready set, report the safety reason.

## Stop Conditions

Stop and report when:

- all selected tasks are completed and final integration review is clean
- if Expert Strict Mode is enabled, the latest Expert final integration review has no accepted material findings
- a blocker requires user/product/external input
- validation fails for a reason that cannot be fixed locally
- the task graph is inconsistent
- no safe serial or parallel execution path remains for the selected ready set
- the user interrupts, redirects, or changes scope
- the same blocker repeats and no independent progress remains

Do not keep looping for wording polish, optional refactors, or non-material preferences.

## Output Shape

While running:

- short updates every meaningful step
- current ready set and chosen execution mode
- current task id or worker lane
- validation/checkpoint status
- Expert Strict Mode pass status when enabled
- blocker status

Final answer:

- completed tasks
- blocked tasks, if any
- validation run
- checkpoint/final review result
- Expert Strict Mode result when enabled
- parallelism decision: isolated parallel write, parallel read-only, or serial fallback, with the safety reason
- changed files or task files updated
- next recommended action

Avoid dumping every task detail into chat; the task files are the durable record.

## Batch Completion Log Guidance

When a checkpoint or final review changes the task set, update `00-overview.md` with:

- checkpoint date
- tasks completed since last checkpoint
- ready-set execution mode and worker assignments when parallelism was used
- material integration findings
- fixes applied or new tasks created
- validation summary
- Expert Strict Mode result when enabled
- remaining blockers

## Quality Bar

A good run keeps the repo coherent after every task and never hides behind a large final review. Each task should be independently explainable, and the final integration review should be about composition, not discovering basic task misses for the first time.

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`: Codex is the canonical source — change it there first, then mirror to `~/.claude/` with the mappings in that file, and keep repo-specific names out of this global skill.
