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
- Codex or Claude as Host Agent, a same-host subagent only as an explicitly accepted degraded fallback, not as the default Expert.

The Host Agent remains responsible for final judgment, edits, validation, and user-facing conclusions.

## External-First Invariant

The highest-value Expert is external or heterogeneous: a different model family, CLI, app-backed connector, separate runtime, or other execution context outside the Host Agent's native subagent pool.

When the user explicitly names `sr-expert`, an external Expert, a heterogeneous model, multi-model review, or when an active `sr-*` workflow enables Expert Strict Mode:

- first attempt an external or heterogeneous Expert path through the preflight rules below;
- do not silently satisfy the request with a same-host subagent;
- if no external or heterogeneous path is available, authenticated, safe, or timely, stop and report that the Expert lane is unavailable unless the user explicitly accepts degraded same-host fallback;
- if degraded fallback is accepted, label it as `same-host fallback` in task logs and user-facing output.

Same-host subagents can still be useful, but they are host workers or degraded reviewers by default. They do not provide the main value of `sr-expert`: heterogeneous external judgment.

## Scoped External Review Consent

When the user explicitly invokes `sr-expert`, an external Expert, a heterogeneous model, multi-model review, or Expert Strict Mode for a repository task, treat that as task-scoped consent to use an external or heterogeneous Expert for the active review lane.

For a Claude CLI review from Codex, this consent covers one of two read-only review shapes, depending on the selected lane: for cold workspace review, exposing the scoped repository or worker workspace so Claude/Anthropic can inspect repo facts independently; for packaged review, sending the active task's current diff, task files, and necessary source snippets. It does not authorize sending secrets, credentials, unrelated directories, browser state, production data, or hidden thread context that the Expert cannot verify.

This consent is not a permission bypass. The Host Agent must still use the approval/escalation mechanism when the adapter requires network, authentication, keychain, filesystem exposure, or third-party model access. The approval request should explicitly state that the user invoked `sr-expert` and authorized this scoped external review, identify the repository or artifact scope, and say that the Expert is read-only unless a separate external implementation lane was chosen.

## Reviewer-Compliant Approval Requests

Reviewers and host approval systems judge the concrete command or connector request, not just this skill's policy. When escalation is needed for external review, make the approval request narrow, auditable, and safe to deny.

The approval request must include:

- `why`: the user explicitly invoked `sr-expert`, an external Expert, or Expert Strict Mode for the active task.
- `destination`: the exact Expert, CLI, connector, or provider that would receive the data.
- `scope`: the exact repository, worker workspace, task file, diff, or artifact boundary.
- `mode`: read-only review unless the user chose an external implementation lane.
- `data boundary`: lane-specific and explicit. For cold workspace review, the scoped repository or worker workspace is the exposure boundary. For packaged review, the boundary is the current diff, task files, and necessary source snippets. In both cases: no secrets, credentials, unrelated directories, browser state, production data, or hidden thread context.
- `fallback`: if approval is denied, mark the external Expert lane unavailable and continue with the primary `sr-*` workflow, a user-approved same-host fallback, or self cold-review as appropriate.

Do not:

- ask for blanket network, filesystem, keychain, or third-party model access.
- describe repository exposure as safe merely because secrets were excluded.
- retry a denied private-workspace exposure by piping, copying, archiving, encoding, or otherwise disguising the same data path.
- use vague approval wording such as "run Claude" or "use an expert" without scope, destination, and data boundary.

Reusable approval wording:

```text
Allow read-only sr-expert review via [Expert/provider] for [repo/worktree/artifact scope].
The user explicitly invoked sr-expert for this task.
Data boundary for cold workspace review: read-only access to the scoped repo/worktree above
so the Expert can inspect repo facts independently. No secrets, credentials, unrelated
directories, browser state, production data, or hidden thread context.
No external writes. If denied, I will skip this Expert lane and continue with [fallback].
```

```text
Allow packaged read-only sr-expert review via [Expert/provider] for [artifact/diff scope].
The user explicitly invoked sr-expert for this task.
Data boundary for packaged review: current diff, task files, and necessary source snippets
only. No secrets, credentials, unrelated directories, browser state, production data,
or hidden thread context.
No external writes. If denied, I will skip this Expert lane and continue with [fallback].
```

If the host reviewer denies or flags the request because private workspace exposure is not acceptable, accept that denial as a real unavailability signal. Do not reframe the same exposure as a different command. Continue through the active `sr-*` workflow and record that the external Expert was unavailable because approval was denied.

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

Implementation note: this skill uses host-agnostic primitives for dispatch decisions ("host-appropriate mechanism", "the host's native subagent or task tool"). Concrete CLI names appear only in symmetric adapter guidance for the Codex <-> Claude paths and are carried in every copy, so the skill remains byte-identical without per-host tool-name or path remapping — unlike sr-* skills that hardcode host tools.

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
3. Select the external or heterogeneous adapter path and run preflight: availability, authentication, permissions, isolation, streaming, observability, and cost. In explicit `sr-expert` or Expert Strict Mode, this preflight happens before considering same-host fallback.
4. For cold workspace review, give the Expert a minimal task and let it inspect the repository facts itself. Prefer starting the Expert with the reviewed repository or worker workspace as its current working directory, so repo discovery stays inside the intended workspace instead of crossing into it by absolute path from another checkout. For packaged lanes, build the Context Package with only the information the Expert needs. If repository or directory exposure may include secrets, get explicit user consent before invoking the Expert.
5. Invoke the Expert using the narrowest feasible workspace, connector scope, or artifact package. For read-only cold review, avoid side effects that commonly trigger extra approval: no edits, report files, tests, builds, generators, package installs, or network commands unless the user explicitly asked for that capability.
6. If the external or heterogeneous Expert path is unavailable and fallback would still be useful, ask whether to continue with degraded same-host fallback. Do not downgrade silently.
7. Treat the Expert result as evidence, not authority: review it, apply only accepted changes, validate in the Host Workspace, and report residual risk.

## Expert vs Host Subagent

Host subagents and external Experts are different tools.

Use the Host Agent's native parallelism (Codex subagents, Claude Tasks/subagents, forked threads, worktree agents) for parallel repo exploration, disjoint implementation slices, independent task execution, and verification that runs in parallel with main work.

Use an external Expert for adversarial review, architecture or design challenge, diff risk scanning, alternative implementation proposals, bounded patches on an isolated surface, or tightly scoped direct implementation by an external CLI/agent when the user wants that Expert to edit code.

Same-host subagents do not satisfy the normal `sr-expert` contract. They may be used as degraded fallback only after an external or heterogeneous path was attempted or judged unavailable, and only after the user explicitly accepts that downgrade. Even then, require a genuinely independent pass: cold packaged context, no reliance on hidden thread assumptions, and a clear output that the Host Agent will review before integration. If a subagent is just parallel execution with shared assumptions, treat it as a host worker, not an Expert.

When a same-host subagent is used as degraded fallback, match it to the lane so it is not silently weaker than the heterogeneous alternative it replaces:

- prefer a different model when one is available; a subagent inheriting the Host's model loses the independence that a heterogeneous Expert provides.
- match the agent type to the lane. Deep cross-document consistency, adversarial review, and design challenge need a full-capability reviewing/reasoning agent; a breadth-first exploration or excerpt-style search agent will locate code but will not reliably audit it.
- record the fallback in the task log or final output as `same-host fallback`, including why no external or heterogeneous Expert was used and whether the user accepted the downgrade.

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

- run from the reviewed repository or worker workspace as its current working directory whenever the adapter supports it
- use `sr-review` / `structured-review` if it is available in the Expert environment; otherwise perform an equivalent findings-first cold worktree review
- start from `git status`, `git diff --stat`, `git diff`, and the changed-file list
- build only the context needed to validate the change, including callers, consumers, tests, fixtures, schemas, migrations, generated contracts, configs, nearby conventions, and invariants as needed
- avoid relying on hidden thread context or the Host Agent's implementation summary
- return material findings only
- remain read-only unless a separate implementation lane was chosen
- return the review as final output or stdout only; do not write a report file
- avoid tests, builds, formatters, generators, package installs, and network commands unless the Host explicitly included them in scope

Host-provided context should be minimal:

- hard constraints: read-only, forbidden paths, excluded files, time budget, validation expectations, security or privacy boundaries
- the exact review target: current worktree, a branch, a base ref, a commit range, a task file, or a worker workspace
- workspace identity: the absolute path or connector workspace id, plus a human-readable label when multiple worktrees exist
- no Host conclusions, suspected bugs, implementation rationale, ranked risks, or "already checked" claims unless the user explicitly wants a verification pass rather than an independent review

When another `sr-*` workflow has already frozen a target, inherit that exact frozen target. Do not independently re-resolve the review target from `git status`, and do not broaden a current-worktree review into branch-ahead commits unless those commits are part of the frozen target.

Use packaged read-only review instead when:

- the Expert cannot safely access the repository or worker copy
- the Expert cannot be started in, or scoped to, the target workspace and cross-workspace filesystem access would require broader permission than the task justifies
- the target is a standalone artifact rather than code in a repository
- exposing the repository is not acceptable
- the question is intentionally narrow, such as checking one API contract, one migration, or one document section

Packaged diff review is a fallback for constrained access, not the preferred path for ordinary code or worktree review. It weakens cold independence because the Host chooses the visible context and may hide the unchanged callers, consumers, schemas, or invariants where the real regression lives.

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
3. Check whether the Expert supports non-interactive prompt mode, read-only mode, scoped directory access, worker worktrees, streaming output, pollable transcript/log output, and tool allow/deny lists.
4. If the Expert would see a repository, directory, browser state, or other surface that may contain secrets, confirm the exposure is covered by the user's task-scoped consent. If the requested surface exceeds the active task scope, get explicit additional consent before invocation.
5. If the Expert requires network, authentication, browser state, OAuth, API keys, keychain access, or local app state, treat that as an external capability and use the host's approval flow.
6. Keep invocation scoped to the concrete Expert command or connector action. Use the Reviewer-Compliant Approval Requests template above: name the user-authorized scope, the destination Expert/provider, the lane-specific data boundary, the read-only or write lane, and the fallback if denied. Do not request broad permanent permission unless the user explicitly wants that tradeoff.
7. Choose the best available observability mode before invocation: native streaming, PTY-visible run, background run with pollable transcript/log, or blocking capture. For external CLI review lanes, prefer a stream/event mode that the Host can poll incrementally; do not start a long Expert run without knowing which mode is in use.
8. Do not override the external Expert's default model by default. Use the CLI/connector's configured default model unless the user explicitly requested a specific model, the active workflow requires a named capability tier, or the Host has just verified an exact model id/alias and can justify the override. Never guess a model alias for cost or speed and still treat the run as the normal Expert gate.
9. If the Expert is unavailable or approval is denied, mark the lane unavailable and continue with the primary `sr-*` workflow.

Explicit `sr-expert` and Expert Strict Mode add one stricter rule: after an external or heterogeneous Expert path is marked unavailable, stop and ask whether to continue with degraded same-host fallback. Do not continue as if same-host review satisfied the Expert gate.

Permission rule:

- Host approval/escalation may fix credential or network access; it does not by itself constrain what the Expert can read or write (see Safety Invariants).
- "Only edit these files" is best-effort unless reinforced by working-directory isolation, CLI tool restrictions, filesystem permissions, connector scopes, or a disposable workspace.
- For direct implementation, run the Expert inside the isolated Worker Workspace, not at the repository root.

Session persistence rule:

- The read-only and no-report-file constraints govern the reviewed workspace's filesystem, not the Expert's own session store. Persisting the Expert's session/transcript in its native client does not write to or pollute the reviewed repo, so a read-only review lane does not require an ephemeral, non-persisted Expert run.
- Keep the Expert session persisted and reviewable in the Expert's native client. Do not pass an ephemeral or no-session-persistence flag merely to satisfy the read-only lane; use it only when the user explicitly wants a throwaway run.
- Capture the Expert session handle (session id, thread id, or resume command) and report it, so the user can reopen the review in the Expert's client.

Adapter entrypoints:

- Codex Host -> Claude Expert: use the Codex -> Claude adapter preference below.
- Claude Host -> Codex Expert: use the Claude -> Codex adapter preference below.
- Same-host subagent:
  - degraded fallback only; use it only after external or heterogeneous preflight fails or is unsafe, and after the user accepts the downgrade
  - use the host's native subagent or task tool instead of pretending it is an external CLI
  - still package the context cold and review the result before integration

## Claude/Codex Adapter Preference

In this environment family, optimize for the two real Expert paths first instead of designing for an abstract unknown CLI.

### Codex Host -> Claude CLI Expert

Preferred adapter when Codex is the Host Agent and Claude CLI is available.

Preflight:

- run `command -v claude` and inspect `claude --help`
- when asking for approval, use the Reviewer-Compliant Approval Requests template: state that the user explicitly invoked `sr-expert` and authorized scoped read-only review, identify Claude/Anthropic as the destination, identify whether this is cold workspace review or packaged review, include the repository/workspace path or artifact boundary, list the lane-specific permitted data boundary, list forbidden surfaces such as secrets, unrelated directories, browser state, and production data, and name the fallback if approval is denied
- prefer `claude -p` non-interactive mode for review lanes
- put the prompt immediately after `-p` / `--print`, before variadic options such as `--tools`, `--allowedTools`, or `--disallowedTools`. If the prompt is placed after those options, the CLI may parse it as another option value and exit with "Input must be provided either through stdin or as a prompt argument when using --print"
- do not rely on delayed stdin for `claude -p` in host exec sessions unless a preflight confirms that the process keeps stdin open; many host runners close stdin at spawn time, causing print mode to exit before a later write can arrive
- do not pass `--model` by default; use Claude CLI's configured default model. Pass `--model` only when the user explicitly requested one, or when a specific id/alias has been freshly verified and the reason for overriding the default is stated.
- if the installed CLI supports it, prefer `--output-format stream-json`; when the CLI requires a paired verbosity flag for stream JSON, include it
- if supported, add partial/event visibility flags such as `--include-partial-messages` or `--include-hook-events` for long reviews; use them for progress detection only, and relay only milestone summaries to the user
- for packaged read-only review that does not require repo tools, disable tools with the CLI's supported mechanism, for example `--tools ""`
- for cold workspace review, run the CLI from the reviewed repository or worker workspace when possible, expose only that directory, and allow only read-only inspection tools where the CLI supports tool scoping
- for cold workspace review intended to avoid approval churn, require final-output/stdout reporting only and forbid report-file writes, tests, builds, generators, package installs, and network commands unless explicitly scoped
- use a debug/transcript/log file when the CLI supports one and the run may be long
- before spawning `claude`, strip the Claude Code nesting-guard variables (`CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_SESSION`, `CLAUDE_CODE_PARENT_SESSION`) from the child environment; if the Host process runs inside a Claude Code session these leak into the child and the spawned `claude` refuses to start with "cannot be launched inside another session"
- keep the review reviewable in the Claude client: Claude CLI persists sessions by default, including print-mode (`-p`) runs, so do not pass `--no-session-persistence`. There is no `--no-thread` flag; `--no-session-persistence` is the only suppressor and it must not be used here. Make the session locatable up front: pass a known `--session-id <uuid>` (or name it with `-n`), and run the Expert from the reviewed repo as its working directory. Report that session id together with the working directory, because Claude sessions are scoped per project; the user reopens the review with `claude --resume <id>` (or `/resume`) from that same directory

Invocation preference:

1. `claude -p "<prompt>" --verbose --output-format stream-json ...` with partial messages/events when available, captured to a pollable log or surfaced by the Host tool. Include `--verbose` only when the installed CLI requires or supports it. This is the default for non-trivial Claude review lanes, including packaged review and cold workspace review.
2. `claude -p "<prompt>" ...` in TTY-visible mode when the Host can surface it safely.
3. `claude -p "<prompt>" --output-format json ...` only when paired with a pollable debug/transcript/log file that provides the live progress channel.
4. Blocking `claude -p "<prompt>" ...` only when the above are unavailable or unsafe, and only after stating that this run is `blocking capture`.

Progress handling:

- parse or skim stream events for observable progress, not hidden chain-of-thought
- relay only milestones: start, files or sections inspected, tools/commands used, emerging material findings, blockers, and finish
- always keep the final complete Claude output for integration review
- for packaged read-only review, combine `--tools ""` with stream JSON when supported, so the Host can still observe token and message progress without granting repository tools
- for cold workspace review, combine stream JSON with the narrow read-only tool scope chosen for the lane
- if stream JSON is written to a log, poll that log for event deltas every 15-30 seconds during active review; summarize only meaningful deltas
- no new stream event means "no observable progress", not proof that the Expert is idle or not spending tokens; do not terminate solely because the final answer has not arrived
- stop a running Claude review only when the user interrupts, a declared time/cost budget is exceeded, the CLI reports an auth/network/tool blocker, or the stream/log produces no events within the declared startup window and continuing would not be worth the cost

### Claude Host -> Codex Expert

Preferred adapter when Claude is the Host Agent and Codex is the Expert.

Preflight:

- prefer a Codex app, connector, thread, or worktree tool when the host exposes one, because it provides the clearest completion signal and workspace isolation
- otherwise inspect `codex --help` or the installed Codex CLI/connector docs for non-interactive mode, streaming or JSON output, transcript/log support, worktree support, and tool scoping
- do not override the Codex connector or CLI default model by default. Specify a model only when the user explicitly requested one, or when a specific id/alias has been freshly verified and the reason for overriding the default is stated.
- verify whether the Codex path shares the Host filesystem; if it does not, require a textual review report, unified diff, or Integration Diff instead of assuming local files changed
- keep the review reviewable in the Codex client: `codex exec` persists the session by default, so do not pass `--ephemeral`. Capture the resulting session id and report it so the user can reopen the review via `codex resume <id>`, `codex fork`, or the Codex desktop app

Invocation preference:

1. Codex app/thread/worktree connector with explicit task package and completion notification.
2. Codex CLI non-interactive mode with streaming/JSON/transcript output when available.
3. Codex CLI with pollable log/transcript.
4. Blocking Codex CLI only when the above are unavailable or unsafe, and only after stating that this run is `blocking capture`.

Integration handling:

- for app/thread based Codex Experts, treat their final message or produced diff as the Integration Diff
- for shared filesystem worktrees, inspect `git status`, changed files, and diff before accepting anything
- do not assume a Codex connector has the same auth, filesystem, or tool permissions as the Claude Host

## Progress Streaming

External expert runs can feel stalled because command output may be buffered, hidden by the host UI, or only visible to the Host Agent.

Use these rules:

- Do not promise that raw Expert output will appear live in the user's host chat panel unless the host tool explicitly supports it.
- Do not ask the Expert to reveal hidden chain-of-thought. Ask for observable progress instead: phase names, files inspected, commands run, blockers, emerging material findings, confidence changes, and final concise rationale.
- Prefer the Expert's native streaming or transcript mode when supported by the installed tool or connector.
- If native streaming is unavailable but a TTY-visible run is safe and supported, prefer that over plain blocking capture for long reviews.
- For mid-run visibility into a long Expert run, prefer native streaming or stdout first. Redirect output to a file or other pollable channel only when that write is inside an approved scratch/log location for the active lane; do not make a read-only cold review write report or transcript files just to get progress. Do not wrap the run in a buffer-until-EOF filter (piping through `tail`, `head`, `less`, `cat`, or similar), which withholds all output until the process exits and makes an actively-running Expert look stalled. Treat that apparent stall as an artifact of the pipe, not evidence to kill the run.
- For external CLI runs expected to take more than a short moment, prefer one of these invocation shapes, in order:
  1. native streaming or stream-JSON mode, if the CLI exposes one;
  2. TTY-visible non-interactive mode, if the host can surface it safely;
  3. background execution whose stdout/stderr or transcript is written to a timestamped file and polled periodically;
  4. blocking capture only when the first three are unavailable or unsafe.
- For Claude CLI reviews from Codex, the normal observable path is stream JSON with partial messages and hook events when supported, written to a pollable log or otherwise surfaced incrementally. Use plain blocking capture only after checking `claude --help` and determining stream JSON, TTY-visible output, and pollable logs are unavailable or unsafe.
- When using a pollable log, announce the log path to the Host Agent's internal notes or task log, poll for meaningful deltas, and summarize milestones instead of dumping raw tokens. Always read the final complete output before integrating.
- If the host automatically re-invokes the Host Agent when a background worker finishes, rely on that notification instead of polling. Poll only channels the host will not surface on its own (an external CLI run, a remote queue, a log-emitting process). Relying on the completion notification does not require giving up an observable log file in the meantime.
- When you do relay progress, summarize meaningful milestones, tool actions, blockers, and changed-file hints instead of dumping every token.
- For direct implementation, ask the Expert to report concise milestones (start, file changes, validation start, finish), but treat those as final-output content unless the invocation is actually streamed or pollable.
- If the host cannot surface live output or the Expert runs as a blocking subprocess, state before the wait that the current Expert invocation is `blocking capture`, explain why streaming/log polling was unavailable or unsafe, and report the final captured output once it returns.
- Always capture the final expert output for integration review, even if intermediate streaming was unavailable.

## Prompt Templates

### Cold Workspace Review

```text
You are an independent external reviewer with no prior thread context.

Review target:
- workspace: <absolute path or connector id for the target repository/worktree>
- workspace label: <human-readable worktree name/id>
- base ref: <base branch/commit, if applicable>
- scope: current worktree changes against the base ref / branch ... / commit range ... / task output ...
- frozen target inherited from Host, if applicable: <exact frozen target; do not broaden>
- explicitly out of scope: <paths, untracked files, staged changes, ahead commits, or other work not included>
- scope rule: use repository commands to verify this target, but do not re-resolve or broaden it from `git status`
- mode: read-only cold workspace review

Run from the target workspace as your current working directory.

If `sr-review` / `structured-review` is available in your environment, use it for the review.
If it is not available, perform an equivalent findings-first cold worktree review.

Constraints:
- read-only review only
- do not edit files
- do not create report files
- do not run tests, builds, formatters, generators, package installs, or network commands
- do not inspect unrelated directories outside this workspace
- do not assume hidden thread context
- ignore any implementation intent unless it is directly visible in the repo, task file, or diff
- excluded paths, if any: ...
- output only in your final response/stdout

Task:
Start by inspecting the repository yourself:
- `git status`
- `git diff --stat <base ref>...`
- `git diff <base ref>...`
- changed-file list
If no base ref applies or it is unavailable, use the plain worktree diff commands instead.

Use these commands to understand and verify the requested target, not to choose a different target. If the requested target is current worktree changes and there is no tracked diff but untracked files exist, report that scope explicitly instead of switching to branch-ahead commits.

Then build only the context needed to validate the change:
- callers and consumers
- tests and fixtures
- schemas, migrations, generated contracts, configs
- nearby conventions and invariants

Focus on material issues that could cause behavioral regressions, contract drift, data inconsistency, missing compatibility, broken rollout/rollback, security/authz gaps, or meaningful test blind spots.

Lead with findings, ordered by severity. For each finding include severity, file/line if available, evidence, why it matters, and a minimal fix direction.
If no material issue is found, say so clearly and list residual risks or validation still needed.
Do not include praise, broad summaries, or low-value style comments.
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
- the Expert session handle (session id or resume command), so the user can reopen the review in the Expert's client
- whether it was external/heterogeneous or a user-accepted same-host fallback
- what the Expert materially found or changed
- what was accepted, rejected, or still uncertain
- what validation was run or skipped

When an Expert was considered but skipped, say briefly why only if it matters to the task outcome.

Do not make the final answer about orchestration mechanics unless the user asked about the orchestration itself.

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`. This skill is host-agnostic and on the no-remap exemption list: keep the Codex and Claude copies byte-identical — do not apply path or tool-name mappings.
