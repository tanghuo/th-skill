---
name: sr-design-gate
description: Use before serious feature work, behavior changes, schema/API/proto/frontend-backend contract changes, or repo-grounded product/architecture brainstorming. Turns rough intent into a confirmed, implementation-ready design artifact before sr-review, sr-plan-split, sr-task-runner, or coding.
---

# SR Design Gate

## Goal

Turn a rough idea, product question, or risky change request into a small, explicit, repo-grounded design before implementation starts.

This skill is the first stage of the local `sr-*` workflow:

1. `sr-design-gate`: clarify intent, inspect current truth, compare approaches, and write a design.
2. `sr-review`: seriously review the design or a completed artifact when needed.
3. `sr-plan-split`: split an approved non-trivial design into executable task files.
4. `sr-task-runner` / `sr-task-loop`: execute and validate tasks.

The output should reduce rework by making business semantics, source-of-truth ownership, contracts, scope, non-goals, validation, and open product decisions explicit before code changes.

## Trigger Rules

Use this skill when the user explicitly names it:

- `sr-design-gate`
- `$sr-design-gate`
- `用 sr-design-gate`
- `sr 开头那个设计门禁`

Also use it when the user asks for design-oriented work before implementation, for example:

- `先别写代码，先评价方案`
- `这个思路怎么样`
- `先帮我梳理方案`
- `产品确认点有哪些`
- `需求还缺什么`
- `brainstorm`
- `头脑风暴`
- `先设计一下`

Use it implicitly for a direct implementation request only when the requested change is non-trivial and likely to cause rework if implemented without a design pass, especially:

- new feature or cross-module behavior change
- schema, migration, proto, OpenAPI, generated client, or frontend-backend contract change
- money, permission, status, lifecycle, scheduling, retry, idempotency, or audit semantics
- room state, RTC, signalling, gift, salary, guild, task progress, or admin/backend contract semantics
- external service integration or asynchronous recovery/reconcile behavior

Do not use this skill for:

- ordinary code review unless the user is asking about design quality or future direction
- small bug fixes with clear desired behavior
- simple refactors where the user clearly wants immediate edits
- small docs cleanup or wording polish
- task execution after an already approved plan

If the user explicitly says to implement immediately and the change is small, do the work. If the user explicitly says to implement immediately but the change is high-risk, state the risk briefly and run a compact design gate before editing.

## Operating Principles

- Ground the design in the current repo, not assumptions.
- Ask only the questions that change the implementation shape.
- Ask one question at a time when user input is needed.
- Prefer multiple-choice questions when the trade-off is known.
- Do not turn every small change into ceremony.
- Keep P1 mainline work separate from P2, future, or optional work.
- Name product-confirmation items separately from engineering decisions.
- Do not bury unresolved decisions inside implementation tasks.
- Do not write code until the design direction is confirmed, unless the user explicitly asks for a short exploratory spike.

## Workflow

If the target repository contains an executable `.local/sr-run.sh` and the user is running a broader `feature-dev` workflow, use it as the phase driver:

- If no active driver workflow exists and the user asked for feature development from rough intent, run `.local/sr-run.sh start feature-dev <target-or-design-artifact> --label <short-label>`.
- If a driver workflow already exists, run `.local/sr-run.sh status` and `.local/sr-run.sh next` before continuing, and follow the reported phase unless it conflicts with newer user instructions.
- After design drafting, design review, split readiness, plan split, block, or completion, record the transition with `.local/sr-run.sh advance <phase> --note <short-note>`, `.local/sr-run.sh block <reason>`, or `.local/sr-run.sh done --note <short-note>`.

The driver records workflow position only. It does not replace design judgment, repo truth gathering, user confirmation, `sr-review`, `sr-split-ready`, `sr-plan-split`, or downstream execution.

### 1. Scope Triage

Decide whether this is:

- `Tiny`: one clear local change; skip this skill unless explicitly invoked.
- `Focused`: one feature or behavior change with limited modules; use a compact gate.
- `Serious`: cross-module, stateful, contractual, financial, permission, lifecycle, external-service, or recovery-sensitive; use the full gate.
- `Too large`: multiple independent subsystems; decompose before designing details.

If the request is too large, stop and propose sub-project boundaries before asking detailed questions.

### 2. Repo Truth Pass

Inspect only the context needed to avoid designing against fiction:

- relevant code paths
- existing docs and plans
- schema/model/proto/OpenAPI/generated client files when contracts are involved
- recent related commits when useful
- tests that define current behavior

Record:

- current source of truth
- current write path and read path
- existing validation and permission gates
- current async/retry/recovery behavior, if relevant
- docs/contracts that may drift from code
- unknowns that require user or product confirmation

### 3. Clarify Intent

Before proposing solutions, clarify the smallest set of requirements that affect architecture or behavior.

Ask one question at a time. Good questions usually target:

- user-visible success criteria
- exact lifecycle/status semantics
- source of truth
- compatibility requirements
- rollout or migration tolerance
- who owns a decision: product, backend, frontend, ops, external provider

If the remaining ambiguity does not change implementation shape, state the assumption instead of asking.

### 4. Present Approaches

Present 2-3 approaches when there is a real choice.

For each approach, include:

- what changes
- why it fits or does not fit the current repo
- operational and data consistency risks
- test and rollout implications
- recommendation

Do not create fake alternatives. If there is only one responsible approach, say so and explain the rejected paths briefly.

### 5. Design Confirmation

Present the recommended design at a detail level proportional to risk.

Cover only the sections that matter:

- goal and non-goals
- affected modules
- data model and contracts
- write path
- read path
- async jobs, retries, recovery, or reconciliation
- permissions and validation
- compatibility, rollout, and rollback
- observability and audit
- tests and acceptance criteria
- product-confirmation items
- residual risks

Ask for confirmation before moving to implementation planning or code.

For compact gates, confirmation can be a short message such as:

```text
Recommended design: <summary>. Main assumption: <assumption>. If that matches your intent, I will implement it this way.
```

For serious gates, write a design artifact.

### 6. Optional Visual Companion

Use a visual companion only when seeing the choice is materially better than reading it.

Good uses:

- admin UI layout or interaction alternatives
- permission/menu/navigation flow comparisons
- state machines, lifecycle diagrams, sequence diagrams, or data-flow diagrams
- architecture boundaries that are easier to validate spatially

Do not use it for ordinary requirements questions, textual trade-offs, backend-only API choices, or anything that can be answered more clearly in prose.

Default visual tools:

- Use Mermaid in the conversation for diagrams when that is enough.
- Use the Browser skill or a temporary local HTML mockup only when the user needs to inspect visual layout or compare options.
- Keep visual artifacts outside the repo unless the user wants them committed.

Before opening a browser-based companion, ask once because it can cost extra time and context:

```text
Some of this may be easier to judge visually. I can show diagrams or mockups in the browser as we go. Want to use that, or keep this text-only?
```

### 7. Write the Design Artifact

Default location:

```text
docs/<topic>-design.md
```

Use a more specific existing docs location if the repo already has one. If the user asks for tasks instead of a design doc, first write or update the minimal design section that makes the tasks executable.

Recommended structure:

```markdown
# <Feature / Change> Design

## Background

## Current Repo Truth

## Goal

## Non-Goals

## Product Confirmation

## Recommended Design

## Alternatives Considered

## Data and Contract Changes

## Rollout and Compatibility

## Validation

## Residual Risks
```

Omit irrelevant sections for small focused work. Keep the artifact specific enough that `sr-review`, `spec-reviewer-prompt.md`, or `sr-plan-split` can operate on it without rereading the whole conversation.

### 8. Design Self-Review

Before asking the user to approve a written design, re-read it and fix material issues:

- placeholders such as `TBD`, `TODO`, or vague future promises
- contradictions between goal, non-goals, and implementation sections
- unclear source of truth
- hidden product decisions
- P1/P2 mixing
- missing validation for risky behavior
- migration or rollback gaps for stateful changes
- contract drift between docs, schema, proto, OpenAPI, generated clients, and code

Do not over-polish wording. Fix issues that would cause wrong implementation, unsafe rollout, or likely rework.

### 9. Optional Spec Review

For serious or high-risk designs, run a second review pass before implementation planning.

Use one of these, in order of availability and value:

- `sr-review` on the written design when the user asked for serious scrutiny or the design affects money, permissions, schema, contracts, lifecycle, async recovery, or external providers.
- A true independent reviewer/subagent when the environment provides one, the design is serious enough to benefit, and the user has not explicitly asked for main-agent-only work.
- Same-thread self-review only for compact gates; label it as self-review, not independent review.

The review should block implementation only for material issues:

- incomplete or contradictory requirements
- ambiguous behavior that could produce the wrong implementation
- unclear source of truth
- hidden product decision
- unsafe rollout or migration gap
- validation too weak for the risk
- P1/P2 scope mixing

Minor wording, style, or optional-example requests should be treated as advisory.

If a separate reviewer prompt is useful, use `spec-reviewer-prompt.md` from this skill directory as the starting point and fill in the actual design path, repo context, and risk focus.

### 10. Handoff

After design confirmation:

- If the design is small, implement directly if the user asked for implementation.
- If the design is non-trivial, invoke or recommend `sr-plan-split`.
- If the design is high-risk or the user asks for scrutiny, invoke or recommend `sr-review`.
- If product decisions remain unresolved, output a product-confirmation list and stop before implementation tasks that depend on those decisions.

## Output Shape

Keep the response shaped to the situation.

For a compact gate:

```markdown
**Repo Truth**
...

**Recommendation**
...

**Assumption**
...
```

For a serious gate:

```markdown
**Current Truth**
...

**Open Product Decisions**
...

**Options**
...

**Recommended Design**
...

**Next Step**
...
```

When writing files, summarize what changed and provide the design path.

## Anti-Patterns

- Starting implementation while the key lifecycle or source-of-truth question is still unresolved.
- Asking many broad questions before reading the repo.
- Producing a generic architecture essay that does not cite local code/docs/schema reality.
- Treating docs as truth when code or schema contradicts them.
- Mixing optional P2 improvements into the P1 path.
- Splitting tasks from a design that still has blocking product decisions.
- Inventing abstractions because a design doc feels more "complete" with them.
- Running a heavy process for a one-line bug fix.

## Skill Maintenance

When editing this skill, follow `~/.codex/skills/SR-SKILLS-SYNC.md`: Codex is the canonical source — change it there first, then mirror to `~/.claude/` with the mappings in that file, and keep repo-specific names out of this global skill.
