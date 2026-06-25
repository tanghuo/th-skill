---
name: sr-worktree-review-fix-loop
description: Use when the user says `循环结构化review` and asks to repeatedly review and fix the current worktree, main workspace, dirty diff, latest local changes, or unstaged/staged code changes until no material issues remain. This wraps sr-review for code/worktree changes instead of replacing it.
---

# SR Worktree Review Fix Loop

## Goal

Turn the high-frequency trigger `循环结构化review` into an executable workflow for the current worktree.

This skill is a thin wrapper around `sr-review` for code/worktree changes. It should remove repeated prompt ceremony without changing the review standard.

Stable success criteria:

- Review the intended worktree changes, not an unrelated old task.
- Freeze material findings before editing.
- Prefer clean-context subagents as an execution accelerator for non-trivial review and repair work when agent tools are available.
- When the user explicitly asks for `sr-expert`, external Expert, multi-model review, an independent/heterogeneous model review, or `Expert Strict Gate`, add an Expert Strict Gate instead of treating the Expert as a one-off side note.
- Fix material defects directly when the user asked for the loop.
- Re-review the original findings and the repair diff.
- Stop when no new material issues remain; do not chase cosmetic preferences forever.
- Be explicit about tests or validation that were run or skipped.

## Trigger Rules

Use this skill when the user says `循环结构化review` and asks for an iterative review-and-fix loop over local code changes, for example:

- `循环结构化review`
- `循环结构化review，尽量开干净 subagent`
- `循环结构化review主工作区的改动，然后修复，直到没有问题`
- `循环结构化review当前 diff`
- `循环结构化review这次本地改动`

Do not use this skill for:

- a simple review-only request
- a simple fix-only request
- iterative review/fix wording that does not include `循环结构化review`, unless the user clearly names this skill
- a named document, spec, plan, or prompt unless the user explicitly frames it as current worktree changes
- remote PR review where the local worktree is not the target
- unrelated skill-maintenance questions about whether this workflow should exist

If the user only asks whether this wrapper should exist, answer the design question first. Create or edit the skill only when the user asks to do so.

## Required Companion Skill

Before reviewing, read `/Users/chenxitang/.codex/skills/sr-review/SKILL.md`.

Apply `sr-review` as the review method. When the target is code diff, commit, or PR, use its `Ordinary Code Review Adapter`:

- findings first
- concrete file and line references
- summaries secondary
- no phase-table output unless the user asks for it

This wrapper controls the loop mechanics; `sr-review` controls review scrutiny.

When the user explicitly asks for `sr-expert`, an external Expert, multi-model review, an independent/heterogeneous model review, or `Expert Strict Gate`, also read `/Users/chenxitang/.codex/skills/sr-expert/SKILL.md` and enable the Expert Strict Gate below.

## Target Resolution

Default target order:

1. If the user named paths, commits, branches, or a diff range, review that exact target.
2. If the user says `主工作区`, `当前工作区`, `worktree`, `dirty diff`, or `当前改动`, review the current checkout's uncommitted changes.
3. If `git status --short --branch` is fully clean, including no untracked files, but the branch is ahead of upstream, review the ahead commits, usually `origin/<base>..HEAD`.
4. If no local git target exists, say so and ask for the target.

Do not reinterpret a requested current-worktree target as ahead commits merely because the branch is ahead of upstream. If the current-worktree target has no tracked diff but has untracked files, treat those untracked files as the candidate worktree target and ask or state the narrowed target before reviewing. Use the ahead-commit fallback only when the checkout is otherwise fully clean or the user explicitly asked for a branch, commit, or ahead-commit review.

Start with read-only commands:

- `git status --short --branch`
- `git diff --stat`
- `git diff`
- `git diff --cached` when staged changes exist
- `git log --oneline --decorate -n 20` or `git cherry -v` when commit-range review is needed

Keep the review tied to the target. Read surrounding code only when needed to avoid false findings or to understand runtime behavior.

## Repo-Local Hard Gate

If the target repository contains an executable `.local/srctl.sh`, use it as the repo-local commit hygiene gate for this loop.

This script is for product-level commit checks only: frozen target membership, staged-diff drift, whitespace checks, and validation bound to the staged diff hash. It does not prove that review happened and does not replace review judgment, materiality decisions, repair design, or validation selection.

Required use:

- After target resolution and before review, repair, or subagent delegation, run `.local/srctl.sh freeze <short-label>`.
- If a freeze already exists, inspect `.local/srctl.sh status`; refresh only when the target legitimately changed, using `.local/srctl.sh freeze --refresh --reason <reason> <short-label>`.
- Stage only the intended coherent change set, then run `.local/srctl.sh check -- <chosen validation command>` so the passing check is bound to the current staged diff hash.
- If multiple validation commands are needed, run supporting commands normally and finish with one srctl check command that runs the required gating set.
- Before any commit that belongs to this loop, ensure `.git/hooks/pre-commit` is installed by `.local/srctl.sh install-hook`; commit normally and let the git hook run `.local/srctl.sh verify`.
- If srctl reports staged files outside the freeze, failed validation, missing check-pass, staged hash drift, or another blocker, do not bypass it with `--no-verify`. Refresh the freeze or rerun check only after explaining why the target or staged content legitimately changed.

If `.local/srctl.sh` is absent, continue with the normal skill workflow. Do not create or modify repo-local srctl tooling unless the user asks for that tooling work.

## Continuation Guardrails

When this workflow resumes from `/goal`, an interruption, compaction, duplicated environment context, or a side conversation handoff, do not restart the loop blindly. First reconcile the current execution state:

- If a target was already frozen in the current goal run, reuse that frozen target after a cheap `git status --short --branch` check confirms it still describes the current checkout; if it drifted, refresh the freeze once and say what changed.
- If material findings were already recorded, continue from the next unfinished step instead of running a fresh full discovery pass unless the target changed.
- Before starting validation, check whether the same validation command is already known to be running in this turn; poll the existing session instead of launching a duplicate.
- Do not issue duplicate read-only discovery commands or duplicate tests in parallel just because repeated goal/context text appears. Use parallelism only for distinct reads or distinct validations.
- After an interruption, assume any previously launched command may still be running until its session is polled or the process state is checked; avoid starting an identical command as the first recovery action.

## Loop Workflow

### 1. Freeze

Record the review target before editing:

- branch and status
- changed files or commit range
- concise baseline of material findings

For each material finding, keep enough information to re-check it:

- file or commit anchor
- line/range or identifiable code anchor
- one-sentence defect
- why it matters

### 2. Review

Lead with material findings ordered by severity.

Treat these as material:

- behavioral regression
- data loss or wrong persistence
- broken API/contract
- authorization/security issue
- concurrency, transaction, or idempotency defect
- test expectation that no longer matches runtime behavior
- doc/schema/code drift that would mislead implementation or release
- validation gap that could hide a real regression

Treat these as non-material unless they affect execution:

- naming taste
- optional example coverage
- wording polish
- low-value refactor preference
- formatting that tools will handle

### 2.5. Agent-Assisted Execution

Default to using subagents as an execution accelerator for this loop when agent tools are available. The loop trigger itself is enough authorization to delegate review or narrowly scoped repair unless the user explicitly says not to use subagents, asks for main-agent-only work, or the environment does not expose a usable agent tool.

The main agent still owns the workflow:

- freeze the target before delegating
- decide which findings are material
- keep write scopes from overlapping
- integrate or reject subagent changes
- run validation
- make the final stop/blocker call

Prefer opening at least one clean-context read-only reviewer after the target is frozen when any of these apply:

- the change is complex, cross-module, or high-risk
- the review target has contract, persistence, concurrency, authorization, retry, schema, or API semantics
- the bug diagnosis could be affected by prior thread assumptions
- multiple independent areas can be reviewed in parallel
- the repair diff is non-trivial and would benefit from independent re-review

Skip subagents when the change is tiny, local, and mechanically obvious; when agent startup cost would exceed the work; when the prompt would need so much hidden context that a clean agent is likely to produce a locally correct but globally wrong answer; or when available agent tools cannot safely inspect the same workspace target.

For independent review, prefer a clean-context read-only pass:

- spawn one `explorer` subagent with `fork_context=false`
- do not set `model`; let it inherit the current model
- ask it to inspect the frozen target or the repair diff only
- tell it not to edit files
- ask for line-anchored material findings, false-positive cautions, and validation gaps

For bug fixing, use a clean-context `worker` when all of these are true:

- the material finding is frozen and can be stated without relying on hidden thread context
- the write scope is concrete and preferably disjoint from the main agent's edits and other worker edits
- the prompt includes the bug, expected behavior, target files or packages, relevant constraints, and validation command
- the worker is told that other agents may be editing the codebase and must not revert unrelated changes
- the worker is told to edit files directly in its forked workspace and list changed files in its final answer

Good subagent tasks:

- independently review the frozen current diff after the main agent has recorded the target
- fix one frozen bug with a narrow write scope and explicit expected behavior
- re-review the repair diff for unresolved or newly introduced material defects
- inspect a narrowly scoped risk area while the main agent validates or repairs a different, non-overlapping issue

Avoid subagents for:

- the immediate blocking step that the main agent must resolve before continuing
- a write scope the main agent is actively editing at the same time
- vague broad exploration that is not tied to the frozen target
- broad, unsupervised rewrites across the same files the main agent or another worker is editing

If subagents are unavailable or skipped, continue in the main agent and say briefly why. Treat subagent output as independent evidence and candidate changes to review, merge, and validate, not as an automatic replacement for the main review.

### 2.6. Expert Strict Gate

Enable this gate only when the user explicitly asks for `sr-expert`, an external Expert, multi-model review, an independent/heterogeneous model review, or `Expert Strict Gate`.

Do not infer this gate merely from requests for a stricter local loop, one-stop review, more careful review, deeper host review, or a stronger host-only workflow. Those requests should make the normal review/fix loop stricter without adding external Expert cost, authentication, repository exposure, or waiting time.

The strict gate turns the loop into:

```text
Host review
-> Host repair
-> validation
-> Expert cold workspace review
-> Host repair of accepted Expert findings
-> validation
-> Host re-review repair diff
-> repeat Expert cold workspace review until Host and Expert gates are clean or blocked
```

Use `sr-expert`'s Cold Workspace Review lane by default. The Expert should be read-only and should start from commands appropriate to the frozen target, such as `git status`, `git diff`, `git diff --cached`, `git ls-files --others --exclude-standard`, `git show`, or the changed-file list. These commands help the Expert verify the frozen target; they must not let the Expert independently re-resolve the review target from repository state.

The Expert scope must exactly match this loop's frozen target:

- if the frozen target is the current worktree diff, Expert reviews the same uncommitted tracked diff plus any explicitly included untracked files
- if the frozen target is named paths or untracked files, Expert reviews only those paths and directly necessary context
- if the frozen target is a commit, branch, or diff range, Expert reviews that exact commit/range
- if branch-ahead commits are not part of the frozen target, tell the Expert they are out of scope even when `git status` shows the branch is ahead

Host context to the Expert should stay minimal:

- the exact frozen review target
- read-only constraint
- excluded paths, ahead commits, or forbidden actions, if any
- validation expectations or time budget, if relevant

Do not send the Host Agent's own suspected bugs, ranked findings, implementation rationale, or "already checked" claims unless the user explicitly asks for verification rather than independent review.

Treat Expert findings as material only after checking them against repo facts. Accepted Expert findings enter the same repair queue as Host findings.

If the Expert is unavailable, unauthenticated, unsafe to expose to the repository, or too slow for the user-approved scope, say so and continue only if the user accepts the degraded mode. Do not silently downgrade the Expert Strict Gate to Host-only review.

### 3. Repair

When material findings exist and the user asked for the loop, fix them directly.

Follow the host repository rules:

- preserve unrelated user changes
- keep edits scoped to the finding
- prefer existing project patterns
- avoid test-only production structure
- use `apply_patch` for manual edits

If a finding cannot be fixed safely without user input, state the blocker and continue with any independent fixes.

### 4. Validate

Run the narrowest useful validation first, then broaden only when risk warrants it.

Typical validation:

- targeted unit tests for touched packages
- package tests when shared behavior changed
- static checks or generated verification when the repo normally requires them
- `git diff --check` for whitespace-sensitive documentation or code changes

If a validation command fails because of environment restrictions, report that clearly and distinguish it from product failure.

### 5. Re-review

After edits, re-check:

- each frozen material finding
- whether the repair introduced new material defects
- whether tests and docs still match the changed behavior
- whether generated files or schemas need syncing
- if subagents were used, whether their findings are fixed, false positives, or accepted residual risks
- if the Expert Strict Gate is enabled, whether the latest Expert cold workspace review has no accepted material findings

If new material findings remain, loop back to Repair.

When the Expert Strict Gate is enabled, do not stop on Host self-review alone after a repair. Stop only after the Host re-review and the latest Expert cold workspace review both have no accepted material findings.

Stop when the active review gates find no new material issues. Say `未发现新的实质问题`, not `绝对没有问题`.

## Output Shape

During the work, keep updates short:

- what target was frozen
- the material issue being fixed
- which validation is running
- whether another pass is needed
- if the Expert Strict Gate is enabled, which Expert pass is running or why it was skipped

Final response:

- state whether the loop stopped because no material issues remain or because of a blocker
- summarize the fixes
- list validation run and any skipped validation
- report the Expert Strict Gate result when enabled
- mention residual non-material risks only if useful

Do not print the full workflow or phase checklist unless the user asks for it.

## Stop Conditions

Stop the loop when:

- all frozen material findings are fixed or intentionally accepted
- the latest re-review finds no new material defects
- if the Expert Strict Gate is enabled, the latest Expert cold workspace review has no accepted material findings
- remaining points are cosmetic, optional, or speculative

Escalate to the user when:

- the same material concern repeats after two repair attempts
- the same Expert finding repeats after two repair attempts and the correct fix is not obvious from code, docs, tests, or schema
- the correct behavior is ambiguous and cannot be inferred from code, docs, tests, or schema
- the fix would require broad unrelated changes
- validation requires credentials, services, or destructive operations the user has not approved

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`: Codex is the canonical source — change it there first, then mirror to `~/.claude/` with the mappings in that file, and keep repo-specific names out of this global skill.
