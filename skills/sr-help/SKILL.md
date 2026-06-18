---
name: sr-help
description: Use when the user asks what the sr-* skills are, which sr skill to use, how sr workflows relate, runner vs loop differences, recommended sr workflow maps, or examples of when not to use a skill. This is a routing and explanation skill, not an execution workflow.
---

# SR Help

## Goal

Explain the `sr-*` skill family clearly enough that the user and Host Agent can choose the right workflow before doing work.

This skill is a lightweight router and map. It does not perform design, review, task splitting, implementation, or expert orchestration by itself. It answers:

- what each `sr-*` skill owns
- which skill should be used for a given user intent
- how skills compose into common workflows
- where boundaries exist between similar skills
- when a skill should not be used

Use it to reduce workflow confusion, not to add ceremony.

## Trigger Rules

Use this skill when the user asks:

- what the `sr-*` skills do
- which `sr-*` skill to use
- how two or more `sr-*` skills differ
- how `sr-task-runner`, `sr-task-loop`, or `sr-worktree-review-fix-loop` relate
- how `sr-expert` fits into other workflows
- for a recommended SR workflow map
- for examples of common SR workflows
- whether a missing workflow should become a new skill or be embedded into existing ones

Do not use this skill when:

- the user already chose a concrete execution skill and wants the work done
- a normal code review, design review, task split, or task run is already clearly requested
- the question is about a non-SR skill family
- the user only needs a quick factual answer that does not depend on SR workflow selection

If the user asks for both help and execution, answer the routing question first, then proceed only if the requested execution target and scope are clear.

## Skill Map

### Design And Planning

- `sr-design-gate`: turns rough intent into an implementation-ready design artifact before serious behavior, schema, API, contract, or architecture work.
- `sr-review`: performs serious findings-first review of a concrete artifact, design, plan, or code change.
- `sr-split-ready`: checks whether a large draft is structured enough to split into execution tasks.
- `sr-plan-split`: turns a mature design, RFC, PRD, or reviewed plan into ordered task markdown files.

### Execution

- `sr-task-loop`: executes one task markdown file through implementation, validation, spec review, code review, repair, and task status update.
- `sr-task-runner`: orchestrates a directory or batch of task markdown files by repeatedly applying `sr-task-loop`, respecting dependencies, checkpoints, and final integration review.
- `sr-worktree-review-fix-loop`: reviews and fixes the current worktree or dirty diff until no material issues remain. It is for existing local changes, not task execution.

### Companion

- `sr-expert`: adds an independent external or cold-context expert lane to another `sr-*` workflow. It is not the primary owner of design, implementation, review, or task execution.

## Choosing The Right Skill

Use this routing table as the default:

- "I have a rough idea / feature / behavior change": use `sr-design-gate`.
- "Review this design, plan, prompt, or non-trivial artifact": use `sr-review`.
- "Is this plan ready to split?": use `sr-split-ready`.
- "Split this plan into task markdown files": use `sr-plan-split`.
- "Run this one task file": use `sr-task-loop`.
- "Run this task directory or batch": use `sr-task-runner`.
- "Review and fix the current dirty diff until clean": use `sr-worktree-review-fix-loop`.
- "Have another model independently check this": use `sr-expert` alongside the active owner skill.

When in doubt:

1. If there is no concrete design yet, start with `sr-design-gate`.
2. If there is a concrete artifact but no task list, use `sr-review` or `sr-plan-split` depending on whether the user asked to critique or execute.
3. If there is exactly one task markdown file, use `sr-task-loop`.
4. If there is a task directory or multiple task files, use `sr-task-runner`.
5. If the target is the current worktree diff rather than task files, use `sr-worktree-review-fix-loop`.
6. If the user wants independent second judgment, add `sr-expert` as a companion, not as the main workflow.

## Common Workflow Maps

### Large Feature

```text
rough intent
-> sr-design-gate
-> sr-review
-> sr-split-ready
-> sr-plan-split
-> sr-task-runner
    -> sr-task-loop per task
-> checkpoint review
-> final integration review
```

Use this when the feature has meaningful design, dependency, contract, data, or rollout risk.

### One Task

```text
task.md
-> sr-task-loop
    -> implement
    -> validate
    -> spec review
    -> code review
    -> repair
    -> update task file
```

Use this when task boundaries are already clear and the user wants one task completed.

### Batch Tasks

```text
task directory
-> sr-task-runner
    -> inventory and dependency ordering
    -> sr-task-loop for next executable task
    -> checkpoint review after meaningful groups
    -> final integration review
```

Use this when work was already split into multiple task markdown files.

### Current Worktree Review And Fix

```text
dirty diff / current worktree changes
-> sr-worktree-review-fix-loop
    -> freeze target
    -> review
    -> repair
    -> validate
    -> re-review
    -> repeat until no material issues remain
```

Use this when the code already changed and the user wants review-and-fix over the current checkout.

### High-Risk Independent Review

```text
active owner workflow
-> sr-expert cold workspace review
-> Host Agent verifies findings
-> Host Agent repairs accepted material issues
-> validation
-> repeat expert review when the reviewed artifact changed
```

Use this when heterogeneity or cold-context independence is worth the overhead.

## Important Distinctions

### `sr-task-loop` vs `sr-task-runner`

`sr-task-loop` owns one task. It reads one task markdown file, implements it, validates it, reviews it, repairs it, and updates that task.

`sr-task-runner` owns a batch. It selects the next executable task, applies `sr-task-loop`, refreshes inventory, runs checkpoint reviews, and performs a final integration review.

Do not use `sr-task-runner` for a single task unless the user explicitly wants runner-level checkpoint or batch semantics.

### `sr-task-loop` vs `sr-worktree-review-fix-loop`

`sr-task-loop` starts from a task file and aims to complete that task.

`sr-worktree-review-fix-loop` starts from existing local changes and aims to remove material issues from the diff.

If there is no task markdown file and the user says "review current changes and fix", use `sr-worktree-review-fix-loop`.

### `sr-review` vs Review-Fix Loops

`sr-review` is review-first and findings-first. It does not imply editing unless the user asks for fixes.

`sr-task-loop` and `sr-worktree-review-fix-loop` are execution loops. They repair material findings when the user asked for the loop.

### `sr-expert` vs Owner Skills

`sr-expert` does not replace `sr-review`, `sr-task-loop`, `sr-task-runner`, or `sr-worktree-review-fix-loop`.

Use it as a companion when independent review, adversarial challenge, comparison, patch proposal, or external implementation materially improves confidence.

For code or dirty worktree review, prefer `sr-expert` cold workspace review when the Expert can safely inspect the repository or a scoped worker copy.

## Anti-Patterns

Avoid these:

- using `sr-task-runner` when there is only one task and no batch concern
- using `sr-task-loop` for an arbitrary dirty diff without a task file
- using `sr-plan-split` before the design is coherent enough to split
- using `sr-expert` as the primary workflow owner
- asking an Expert to review only the Host Agent's summary when the goal is independent code review
- turning a review-only request into edits without user authorization
- continuing a task runner past a dependency blocker that should stop downstream work
- adding new skills when a small integration rule inside an existing skill would be clearer

## Output Guidance

When answering a help request:

- start with the direct recommendation
- briefly explain why that skill or workflow fits
- mention adjacent skills only when the distinction matters
- include a compact workflow map when useful
- avoid reciting every skill unless the user asked for the full map

If the user asks for a missing workflow:

1. Decide whether it is a new primary workflow, a companion behavior, or a rule that belongs inside an existing skill.
2. Prefer extending an existing owner skill when the workflow depends on that owner's state machine.
3. Suggest a new skill only when it has a distinct trigger, owner, and stop condition.

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`. This skill is host-agnostic and should be mirrored byte-identical between Codex and Claude.
