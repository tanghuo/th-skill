---
name: sr-expert
description: Use inside sr-* workflows when an external expert agent, CLI, or heterogeneous model may materially reduce risk, especially cross-checks, adversarial reviews, comparison passes, bounded patch proposals, or isolated external implementation. This is a companion orchestration skill, not a replacement for sr-review, sr-task-loop, or sr-task-runner.
---

# SR Expert

## Goal

Add a disciplined external-expert lane to the `sr-*` workflow: decide when to involve an external expert, when to preserve cold independence instead of packaging context, how to run it safely, and how to integrate the result without weakening the Host Agent's ownership.

It is intentionally conservative. External experts should reduce risk or latency, not become ceremony.

## Core Roles

Use role names instead of product names.

- `Host Agent`: the current agent running the primary `sr-*` workflow and talking to the user.
- `Expert`: the external model, CLI, agent, or session being consulted.
- `Host Workspace`: where final integration, validation, and user-facing decisions happen.
- `Worker Workspace`: an isolated worktree, branch, temporary copy, or external session where the Expert may inspect or implement.
- `Integration Diff`: the patch, commit, changed-file list, review report, or decision memo returned from the Expert to the Host Agent.

Examples:

- Codex as Host Agent, Claude CLI as Expert.
- Claude as Host Agent, Codex CLI/app/thread as Expert.
- Codex as Host Agent, a Codex subagent as Expert.
- Claude as Host Agent, a Claude subagent or Task as Expert.

The Host Agent remains responsible for final judgment, edits, validation, and user-facing conclusions.

## Safety Invariants

Two rules apply to every lane below. They are stated once here and referenced, not repeated.

- **Secrets stay out, and exclusion is not protection.** Never put secrets, tokens, credentials, keys, or passwords in the Context Package. But if the Expert can reach the repository or directory, the repository itself is the exposure surface — do not claim secrets are safe merely because the package excluded them. Pass only the minimum directory or artifact the Expert needs, and expose secret-bearing repos only with explicit user consent.
- **Never let an Expert write without a recoverable baseline.** Before any external write, record `git status`, identify unrelated dirty files, and ensure every file that could be touched has a recovery point (clean tree, commit, stash, patch backup, or copy). A fresh git worktree starts from committed state, so any dirty context the Expert needs must be committed, applied into the worker, backed up as a patch, or included in the Context Package. When hard filesystem isolation is unavailable, allowed write scope is a review contract, not a security boundary — rely on post-run diff review against the baseline.

## Position In The SR Family

`sr-expert` is a companion skill. Use it alongside the primary `sr-*` skill that owns the work:

- `sr-review` owns serious artifact review.
- `sr-design-gate` owns design readiness.
- `sr-plan-split` owns executable task splitting.
- `sr-task-loop` owns one task's implementation loop.
- `sr-task-runner` owns task DAG execution.
- `sr-worktree-review-fix-loop` owns iterative dirty-worktree review and repair.

`sr-expert` only answers: whether an external expert is worth invoking, which lane to use, whether to use a cold workspace entry or a packaged context, which adapter or CLI path is safe and available, and how to verify and integrate the response.

Implementation note: this skill uses host-agnostic primitives for dispatch decisions ("host-appropriate mechanism", "the host's native subagent or task tool"). Concrete CLI names appear only as symmetric adapter examples, not as host-specific dispatch requirements. Its copies across host skill directories may therefore be kept byte-identical without per-host tool-name or path remapping — unlike sr-* skills that hardcode host tools.

## Cost Gate

Apply this gate before choosing a lane.

Invoke an Expert only when the expected value of heterogeneity, independence, speed, or implementation leverage is greater than the cost of packaging context, running the Expert, and integrating the result.

Default decision: if you cannot articulate why external expert work beats local validation or a normal host subagent, do not invoke `sr-expert`.

## When To Use This Skill

Use this skill when any of these hold:

- the user explicitly names `sr-expert`, external/second/outside expert, multi-model, heterogeneous review, or cross-check
- the user names another model, CLI, or agent intending to consult, coordinate with, review through, or delegate work to it
- another active `sr-*` skill needs a genuinely independent pass (not same-thread self-review) and a suitable Expert is available
- a wrong answer would affect money, data correctness, security, migrations, API contracts, or rollout safety
- a design has multiple plausible approaches and local context may bias the Host Agent
- a diff is large, or crosses module boundaries where edge cases, naming, ownership, or transaction boundaries can drift
- a host worker finished non-trivial work and an adversarial second opinion could catch integration risk

Do not use this skill when:

- the Cost Gate fails
- the work is small, mechanical (renames, formatting, wording), or the next step is obvious and cheap to validate locally
- the request is already blocked on a user or product decision
- useful context cannot be packaged without secrets or sensitive production data, or without hidden thread context the Expert cannot verify
- the Expert is unavailable, unauthenticated, or network-blocked, or its result would arrive too late for the critical path
- it would create overlapping write scope where two agents edit the same files without a clear owner
- it means direct external implementation in a dirty main worktree without a recoverable baseline

Do not invoke just because subagents or an Expert CLI happen to be available.

## Procedure

Use this decision sequence:

1. Apply the Cost Gate and decide whether an Expert is justified.
2. Choose one lane: cold workspace review, packaged read-only review, adversarial challenge, patch proposal, comparison pass, or external implementation.
3. Select the adapter path and run preflight: availability, authentication, permissions, isolation, streaming, and cost.
4. For cold workspace review, give the Expert a minimal task and let it inspect the repository facts itself. For packaged lanes, build the Context Package with only the information the Expert needs. If repository or directory exposure may include secrets, get explicit user consent before invoking the Expert.
5. Invoke the Expert using the narrowest feasible workspace, connector scope, or artifact package.
6. Treat the Expert result as evidence, not authority: review it, apply only accepted changes, validate in the Host Workspace, and report residual risk.

## Expert vs Host Subagent

Host subagents and external Experts are different tools.

Use the Host Agent's native parallelism (Codex subagents, Claude Tasks/subagents, forked threads, worktree agents) for parallel repo exploration, disjoint implementation slices, independent task execution, and verification that runs in parallel with main work.

Use an external Expert for adversarial review, architecture or design challenge, diff risk scanning, alternative implementation proposals, bounded patches on an isolated surface, or tightly scoped direct implementation by an external CLI/agent when the user wants that Expert to edit code.

Same-host subagents can count as Experts only when they provide a genuinely independent pass: cold packaged context, no reliance on hidden thread assumptions, and a clear output that the Host Agent will review before integration. If a subagent is just parallel execution with shared assumptions, treat it as a host worker, not an Expert.

When a same-host subagent stands in for an Expert, match it to the lane so it is not silently weaker than the heterogeneous alternative it replaces:

- prefer a different model when one is available; a subagent inheriting the Host's model loses the independence that a heterogeneous Expert provides.
- match the agent type to the lane. Deep cross-document consistency, adversarial review, and design challenge need a full-capability reviewing/reasoning agent; a breadth-first exploration or excerpt-style search agent will locate code but will not reliably audit it.

When both apply:

1. Keep the task DAG and dependency order from the active `sr-*` skill.
2. Use host subagents for independent execution lanes.
3. Use the Expert as reviewer, critic, patch proposer, or isolated worker for a specific lane.
4. Keep the Host Agent as integrator and final reviewer.

Never assign the same file set to two writers. If a host worker and an Expert touch the same area, one must be read-only.

## External Expert Lanes

Choose one lane. Do not send a vague "look at this" request.

### 1. Cold Workspace Review

Default to this lane for code changes, dirty worktree review, worker output review, or "another agent already implemented this; independently review it" requests when the Expert can safely read the repository or a scoped worker copy.

This lane exists because the main value of a heterogeneous Expert is often independent context discovery. If the Host Agent pre-summarizes the change, selects only snippets, or explains its own suspicions, the Expert becomes a second reader of the Host's framing instead of an independent reviewer.

Ask the Expert to:

- start from `git status`, `git diff`, and the changed-file list
- build its own context from the repository, including callers, consumers, tests, schemas, generated contracts, and nearby conventions as needed
- avoid relying on hidden thread context or the Host Agent's implementation summary
- return material findings only
- remain read-only unless a separate implementation lane was chosen

Host-provided context should be minimal:

- hard constraints: read-only, forbidden paths, excluded files, time budget, validation expectations, security or privacy boundaries
- the exact review target: current worktree, a branch, a commit range, a task file, or a worker workspace
- no Host conclusions, suspected bugs, implementation rationale, ranked risks, or "already checked" claims unless the user explicitly wants a verification pass rather than an independent review

Use packaged read-only review instead when:

- the Expert cannot safely access the repository or worker copy
- the target is a standalone artifact rather than code in a repository
- exposing the repository is not acceptable
- the question is intentionally narrow, such as checking one API contract, one migration, or one document section

### 2. Packaged Read-Only Review

Use for serious diffs, plans, task outputs, or generated artifacts.

Ask for:

- concrete findings only
- severity or priority
- exact file and line references when possible
- no edits
- no praise or restatement unless needed to justify a finding

### 3. Adversarial Challenge

Use for designs, architecture choices, migration plans, and high-risk assumptions.

Ask the Expert to:

- argue against the current approach
- identify hidden assumptions
- find missing rollback, compatibility, or validation steps
- propose safer alternatives only when materially different

### 4. Patch Proposal

Use only for an isolated file set or module.

Ask for:

- a unified diff or explicit file-level edits
- no changes outside the assigned scope
- a short rationale per changed area
- tests that should be run

The Host Agent must review and apply the patch deliberately. Do not treat a generated patch as accepted just because it applies.

### 5. Comparison Pass

Use when two approaches are plausible.

Ask for:

- decision criteria
- pros and cons tied to repo facts
- failure modes
- a recommendation with confidence and assumptions

### 6. External Implementation

Use when the user wants the Expert to directly edit code. Treat this as an external worker lane, not another cursor in the main working tree.

Default shape:

```text
Host Agent freezes task and acceptance criteria
-> Host Agent creates an isolated Worker Workspace
-> Expert implements there
-> Host Agent collects Integration Diff and changed-file summary
-> Host Agent reviews, applies, validates, and integrates in the Host Workspace
```

Prefer this lane for:

- isolated files or packages
- tests, generated helpers, or low-risk implementation slices
- code changes whose acceptance criteria are already clear
- situations where the user explicitly wants the Expert to be the implementer

Avoid this lane for:

- unresolved design questions
- broad cross-module refactors
- money, security, migration, transaction, or API-contract changes without a frozen plan
- areas already owned by another worker in the same run
- dirty worktrees where the Expert could overwrite unrelated user changes

Before invoking (the recoverable-baseline invariant applies):

- choose the Worker Workspace where the Expert will run; prefer a disposable git worktree, branch, or temporary copy. Run in the Host Workspace only when it is clean, or when all touched dirty files have a recovery point.
- define exactly: allowed write scope, forbidden paths or behaviors, required validation, and whether the Expert may run tests or only edit files
- for high-risk domains, require a frozen plan first and assign the Expert only a narrow implementation slice

Ask the Expert to:

- edit only the allowed files or directories
- preserve unrelated changes
- stop and report if the needed change exceeds the allowed scope
- summarize changed files and validation performed

After it returns:

- pick the integration path:
  - shared filesystem or worktree: inspect the resulting `git diff`, changed-file list, or worker commit before any other step
  - non-shared app/thread/session: require a textual unified diff, commit summary, or file-by-file patch, and reconstruct it in the Host Workspace before review
- verify that changed files are within the allowed write scope
- apply only accepted hunks to the Host Workspace
- rerun the relevant validation in the integration workspace
- discard the Worker Workspace only after the result is integrated or intentionally rejected

## Context Package

Before invoking an Expert in a packaged lane, prepare a compact package. For cold workspace review, do not prepare a rich Context Package; send a minimal entry prompt and let the Expert discover the relevant repo facts.

Include:

- objective
- active `sr-*` phase or task file
- source plan or acceptance criteria
- relevant file paths
- relevant diffs or snippets
- when the change modifies or replaces an existing file, the pre-change version of every in-scope file, not just the new artifact; "this replacement silently drops content that was in the old file" is structurally invisible to the Expert without that baseline
- known constraints and out-of-scope items
- exact question to answer
- expected output shape
- Host Agent and Expert identities, if they affect available tools or permissions

Exclude:

- secrets and sensitive data (see Safety Invariants)
- unrelated repo history
- broad instructions to inspect everything
- hidden assumptions the Expert cannot verify
- the Host Agent's own findings, conclusions, or a ranked list of suspected problems; pre-stating them anchors the Expert toward confirming your guesses instead of independently finding what you missed. Give the question and the constraints, not the answer.

For code or worktree review, prefer cold workspace review when the Expert can safely read the repository or a scoped worker copy. Ask it to start from `git status` and `git diff`, then follow the context it needs. Use `git diff -- path...`, `git show`, or named file excerpts only when repository access is unsafe, unavailable, or intentionally narrower than the review goal.

## Expert CLI Preflight And Invocation

Use this section for any external CLI, model agent, or app-backed expert. Do not assume a specific command, auth store, or streaming mode. Inspect the installed tool or host-provided connector first when needed.

Preflight:

1. Check whether the Expert is available using the host-appropriate mechanism.
2. If sandboxing may hide the user's real PATH, credentials, keychain, browser session, or config, confirm availability through the host's approval/escalation mechanism before declaring the Expert unavailable.
3. Check whether the Expert supports non-interactive prompt mode, read-only mode, scoped directory access, worker worktrees, streaming output, and tool allow/deny lists.
4. If the Expert would see a repository, directory, browser state, or other surface that may contain secrets, get explicit user consent for that exposure before invocation.
5. If the Expert requires network, authentication, browser state, OAuth, API keys, keychain access, or local app state, treat that as an external capability and use the host's approval flow.
6. Keep invocation scoped to the concrete Expert command or connector action. Do not request broad permanent permission unless the user explicitly wants that tradeoff.
7. If the Expert is unavailable or approval is denied, mark the lane unavailable and continue with the primary `sr-*` workflow.

Permission rule:

- Host approval/escalation may fix credential or network access; it does not by itself constrain what the Expert can read or write (see Safety Invariants).
- "Only edit these files" is best-effort unless reinforced by working-directory isolation, CLI tool restrictions, filesystem permissions, connector scopes, or a disposable workspace.
- For direct implementation, run the Expert inside the isolated Worker Workspace, not at the repository root.

Adapter examples:

- Codex Host -> Claude Expert:
  - availability: `command -v claude` and `claude --help`, as supported by the installed CLI
  - auth preflight: `claude auth status`, when supported
  - invocation: `claude -p ...`, with scoped directories and tool restrictions when supported
  - common hazard: Codex command sandbox may not see Claude OAuth or macOS Keychain state; verify through host escalation before asking the user to log in again
- Claude Host -> Codex Expert:
  - availability: use the host-provided Codex connector/app/thread tool when available; otherwise inspect whether a Codex CLI is installed and supports non-interactive execution, for example by checking `command -v codex` and the installed tool's help output
  - auth preflight: use the Codex connector or CLI's own status/help/auth mechanism, if available
  - invocation: prefer a new Codex thread, Codex worktree, or non-interactive Codex CLI run with a self-contained Context Package; if the Codex path is app/thread based and does not share the host filesystem, require a textual Integration Diff instead of expecting local files to change
  - common hazard: Claude's shell/session may not share Codex app login state, API-key environment, workspace trust, or connector permissions
- Same-host subagent:
  - use the host's native subagent or task tool instead of pretending it is an external CLI
  - still package the context cold and review the result before integration

## Progress Streaming

External expert runs can feel stalled because command output may be buffered, hidden by the host UI, or only visible to the Host Agent.

Use these rules:

- Do not promise that raw Expert output will appear live in the user's host chat panel unless the host tool explicitly supports it.
- Prefer the Expert's streaming output mode when supported by the installed tool or connector.
- For mid-run visibility into a long Expert run, redirect its output to a file or other pollable channel and read it incrementally. Do not wrap the run in a buffer-until-EOF filter (piping through `tail`, `head`, `less`, `cat`, or similar), which withholds all output until the process exits and makes an actively-running Expert look stalled. Treat that apparent stall as an artifact of the pipe, not evidence to kill the run.
- If the host automatically re-invokes the Host Agent when a background worker finishes, rely on that notification instead of polling. Poll only channels the host will not surface on its own (an external CLI run, a remote queue, a log-emitting process). Relying on the completion notification does not require giving up an observable log file in the meantime.
- When you do relay progress, summarize meaningful milestones, tool actions, blockers, and changed-file hints instead of dumping every token.
- For direct implementation, ask the Expert to report concise milestones (start, file changes, validation start, finish), but treat those as final-output content unless the invocation is actually streamed or pollable.
- If the host cannot surface live output or the Expert runs as a blocking subprocess, state that live progress is unavailable and report the final captured output once it returns.
- Always capture the final expert output for integration review, even if intermediate streaming was unavailable.

## Prompt Templates

### Cold Workspace Review

```text
You are an independent external reviewer with no prior thread context.

Review target:
- repository or worker workspace: ...
- scope: current worktree changes / branch ... / commit range ... / task output ...

Constraints:
- read-only review
- do not edit files
- do not assume hidden thread context
- ignore any implementation intent unless it is directly visible in the repo, task file, or diff
- excluded paths, if any: ...

Task:
Start from git status, git diff, and the changed-file list. Build your own context from the repository: callers, consumers, tests, schemas, generated contracts, nearby conventions, and validation paths as needed.

Return only material findings. For each finding include severity, file/line if available, why it matters, and a minimal fix direction.
If no material issue is found, say so and list residual risks.
```

### Packaged Read-Only Review

```text
You are an external reviewer with no prior thread context.

Host Agent:
...

Objective:
...

Review target:
- paths:
  - ...
- diff or artifact:
...

Constraints:
- read-only review
- do not edit files
- do not assume hidden thread context
- ...

Task:
Return only material findings. For each finding include severity, file/line if available, why it matters, and a minimal fix direction.
If no material issue is found, say so and list residual risks.
```

### Patch Proposal

```text
You are proposing a bounded patch, not committing it.

Allowed write scope:
- ...

Do not change:
- ...

Return a unified diff plus validation commands.
```

### External Implementation

```text
You are implementing in an isolated Worker Workspace as an external expert.
The Host Agent will review and integrate your diff in the Host Workspace.

Host Agent:
...

Allowed write scope:
- ...

Existing dirty files or user changes to preserve:
- ...

Do not change:
- ...

Acceptance criteria:
- ...

Validation:
- ...

If the task requires edits outside the allowed scope, stop and report the blocker instead of expanding the change.
Report concise progress milestones while working if the Expert tool supports streaming.
When finished, report changed files, important decisions, validation run, and the final diff or commit reference.
```

## Integration Rules

External expert output is evidence, not authority.

The Host Agent must:

- check findings against actual repo files or artifact text, and discard findings based on wrong assumptions
- apply patches only after review; inspect direct external implementation diffs before accepting them
- verify external worker changes against the allowed write scope, and revert or repair out-of-scope changes while preserving unrelated user work
- run appropriate validation when code changes are adopted
- report skipped validation or unavailable expert checks
- re-run an independent Expert pass after editing the reviewed artifact in response to the findings: once the Host Agent changes the artifact, the original Expert pass is stale and never saw the edited version. Do not close on same-thread self-review; the Host's own fixes can introduce new contradictions (e.g. a freshly added constraint that conflicts with an existing section) that only a fresh independent pass over the changed artifact will catch.

If expert output conflicts with an active `sr-*` skill, follow this order:

1. user instructions and safety constraints
2. repo facts, validation results, and recoverability of the worktree
3. active primary `sr-*` skill
4. `sr-expert` guidance
5. external expert recommendation

## Output Shape

Keep user-facing output compact.

When an Expert was used, say:

- which lane was used
- which adapter or Expert path was used
- what the Expert materially found or changed
- what was accepted, rejected, or still uncertain
- what validation was run or skipped

When an Expert was considered but skipped, say briefly why only if it matters to the task outcome.

Do not make the final answer about orchestration mechanics unless the user asked about the orchestration itself.

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`. This skill is host-agnostic and on the no-remap exemption list: keep the Codex and Claude copies byte-identical — do not apply path or tool-name mappings.
