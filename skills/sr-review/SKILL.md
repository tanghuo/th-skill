---
name: sr-review
description: Short alias for structured-review. Use when the user explicitly names sr-review, structured-review, or 结构化review, or asks for serious red-team, multi-perspective, fresh-context, exhaustive, or iterative review of a concrete non-trivial artifact such as an important plan, spec, architecture, decision memo, prompt, or completed draft. Do not use for routine code review, small edits, or simple questions unless the user explicitly names this skill; then keep the host findings-first review format.
---

# SR Review

## Goal

Help important work survive serious review by separating creation, scrutiny, repair, and final recommendation.

This skill supports three task types:

- design a new solution
- review an existing artifact
- revise an artifact after critique

It should reduce hidden assumptions, missing steps, vague success criteria, weak alternatives, implementation risk, and rework.

This skill is mostly text-review oriented.

Stable success criteria:

- Trigger only for explicit Skill naming or for serious review of a concrete, non-trivial artifact.
- Lead artifact and code reviews with the strongest finding, not with praise, reassurance, or process framing.
- Never claim a same-thread pass or an unrun package is a truly independent review.
- Keep output shaped to the task instead of printing a fixed template.
- For iterative review-and-fix requests, keep looping only while material defects remain; do not chase wording-only preferences indefinitely.

## Input and Verification Boundaries

Allowed inputs:

- artifact text supplied in the conversation
- a Skill file, prompt, plan, spec, decision memo, or other local artifact explicitly named by the user
- a commit, diff, PR, patch, or generated artifact explicitly named by the user
- supporting material the user explicitly asks to verify

Input gathering means reading the supplied artifact or user-named target. It also includes read-only local commands needed to inspect that target or produce exact references, such as `rg`, `sed`, `nl`, `ls`, `wc`, `git show`, `git diff`, or `git status`.

Context inspection means reading directly related files only when the target itself requires repo/runtime/source consistency, when the user asks for alignment checks, or when line-level code review needs the surrounding implementation to avoid false findings. Keep the inspection tied to the named target and mention material extra context in the answer.

External verification means browsing, running tests/builds/migrations, invoking services, checking source-of-truth material that is neither mentioned nor directly required by the target, inspecting unrelated files, or using sources beyond the named target and its direct context.
Do not perform unrequested external verification during the review phase unless higher-priority environment instructions require it. If verification would materially change the conclusion, mark it as needed instead of silently browsing, running tests, invoking services, or inspecting unrelated files.

For revision tasks, distinguish the initial review phase from the repair and validation phase. After the frozen findings are recorded, editing the user-named artifact is allowed when the user asked for fixes and the active environment permits edits. Cheap local readback, diff, line-reference, markdown parsing, or other artifact-local validation is allowed when it directly checks the edited target. Browsing, tests/builds, service calls, migrations, unrelated source inspection, and source-of-truth checks that are neither mentioned nor directly required by the target remain external verification unless the user asked for them, the host instructions require them, or the artifact type cannot be responsibly validated without them. Report any meaningful validation that was skipped.

When the user supplies both pasted artifact text and a local path, commit, or diff, first determine the primary review target from the wording. If it is cheap and useful, compare the pasted artifact with the named target using read-only checks; otherwise review the primary target and state the assumption.

## Hard Truth About Fresh Context

Same-thread `fresh-context review` is only a simulation. The model still holds the surrounding context and may preserve earlier assumptions. Use the simulated pass to force stricter reading. Do not treat it as a true independent review.

During the simulated pass, separate the evidence mentally:

- artifact facts: visible in the frozen artifact or user-named input
- contextual assumptions: background from the thread or direct context that affects the conclusion
- excluded context: prior conversation or unstated intent that should not support a finding

You do not need to print all three categories unless scope is disputed, but findings should not depend on excluded context.

If the work is genuinely important and independent review would materially reduce approval risk, produce an `External Review Package`.
Actually run it when the current environment supports a real independent context and the user has not explicitly asked for main-agent-only work.
Executable test: a real independent context means a separate model, agent, or session with no prior thread context is available as a callable tool and is actually run. A subagent / sub-session / new chat that starts cold (no carry-over of this thread's context window) counts when the environment exposes it and the task can be safely delegated; if the user forbids subagents, the environment lacks a callable tool, or the task cannot be safely delegated, treat them as unavailable.
If no such tool is available or appropriate, or if only same-thread self-review is possible, provide the package only and state that it has not been run.

## Trigger Rules

Trigger this skill only when one branch applies.

### A. Explicit Skill Invocation

Use this skill unconditionally only when the user explicitly names the Skill or the structured-review method:

- `sr-review` / `$sr-review`
- `structured-review` / `Structured Review` when used as a named method
- `结构化review` / `结构化 review`
- `$structured-review`
- `用 sr-review 技能`
- `用 structured-review 技能`

Do not treat bare generic wording such as `structured review`, `结构化审查`, or `结构化评审` as an unconditional trigger by itself. Route those through Serious Artifact Review Invocation or Artifact Review Context, where the target must still be concrete and non-trivial.

If the target is an ordinary code diff, commit, or PR, use the Ordinary Code Review Adapter instead of artifact-review templates.

### B. Serious Artifact Review Invocation

Use this skill when all of these are true:

1. The user provides or names a concrete, non-trivial artifact or explicit review/revision target.
2. The user asks for serious scrutiny using wording such as:
   - `反复打磨` / `iterative refinement`
   - `多角度` / `multi-perspective`
   - `红队` / `red team`
   - `新上下文` / `fresh context`
   - `冷启动审查` / `cold review`
   - `大方案评审` / `major plan review`
   - `完整审查` / `穷尽审查` / `Exhaustive`
   - `深度review` / `深度审查` / `deep review`
   - `仔细完整` / `严格审查`
3. The target is larger or riskier than a small local change, routine code diff, simple naming question, or wording tweak.

These scrutiny phrases are not direct invocations by themselves. For example, `红队下这个变量名` or `新上下文看一眼这句话` should stay lightweight unless the user explicitly names `structured-review` or attaches a non-trivial artifact.

Do not treat weak value phrases as invocations by themselves:

- `减少返工` / `reduce rework`
- `认真看看`
- `帮我看漏了什么`

These weak phrases trigger the skill only when they are attached to a concrete, non-trivial artifact or explicit review/revision target and the user is asking for real review or revision. Otherwise, use the default lightweight answer.

### C. Artifact Review Context

Use this skill when there is no direct keyword match but all of these are true:

1. The user provides a complete artifact such as a plan, design, spec, decision memo, PR description, prompt, or draft.
2. The user asks for review with terms such as `评审`, `审视`, `找问题`, `看风险`, or equivalent wording.
3. The artifact is larger or riskier than a small local change, routine code diff, or wording tweak.

If neither branch applies, use the default lightweight answer or normal findings-first review workflow.

Do not use this skill implicitly for:

- ordinary code review without explicit Skill invocation
- small implementation changes without explicit Skill invocation
- simple questions without explicit Skill invocation
- routine wording polish without explicit Skill invocation
- tasks where the user clearly wants direct implementation without a review request, prior critique, or explicit `structured-review` invocation

For normal code review, use the default findings-first review workflow unless the user explicitly asks for this skill.

## Rule Precedence

When instructions pull in different directions, apply this order:

1. Explicit Skill naming wins. The authoritative list of explicit-naming forms lives in `Trigger Rules § A`; any form listed there (including the space variant `结构化 review`) bypasses the non-trivial-artifact gate. Forms not listed there do not.
2. Serious scrutiny phrases such as `红队`, `多角度`, `新上下文`, `深度review`, `完整审查`, or `穷尽审查` require a concrete, non-trivial artifact or review/revision target.
3. Routine-task exclusions block implicit triggering. Ordinary code review, small edits, simple questions, and direct implementation requests do not trigger this skill unless the user explicitly named it.
4. For ordinary code review with an explicit `structured-review` request, keep the host's findings-first review format and use this skill only to increase scrutiny. Do not force phase headings, phase tables, or artifact-review templates.
5. For combined review-and-fix requests, freeze and report the review findings before presenting repair direction or a rewrite. Do not silently repair defects during the review pass.
6. Choose task type and review intensity after the trigger decision. Invoking `structured-review` enables the skill; it does not automatically select the highest intensity.
7. The phase checklist is internal. Output compression and findings-first review shape take priority over printing every selected phase.
8. Tool boundaries remain in force. During the review phase, read user-named local artifacts and run read-only commands for those targets as input gathering; mark external verification as needed unless the user asked for it or the environment instructions require it. During revision validation, apply the Input and Verification Boundaries distinction between artifact-local validation and external verification.

## Task Type and Intensity

Choose one task type and one review intensity. Do not ask the user to choose unless the request is truly ambiguous.

Task type:

- `Design`: create a new plan or approach.
- `Review`: inspect an existing artifact without rewriting it.
- `Revision`: repair an artifact or plan after critique.

For combined requests such as `review and fix`, `审查并帮我改`, or `看着修下`, choose `Revision`, but keep two steps distinct:

1. Freeze the artifact and identify the strongest review findings without rewriting while reading.
2. Then provide the repair direction, rewritten artifact, or file edits with a clear change summary.

For local-file revision, record a lightweight baseline before editing: target path plus the current diff, line references, or a short frozen-summary of the defects being fixed. After the change, re-check the original severe findings instead of only describing the new text.

Iterative review-and-fix requests:

- Treat requests such as `反复 review 并修`, `review 到没问题为止`, or `deep review, fix, then review again` as `Revision` with `Intensive` intensity unless the user clearly asks for a lighter pass.
- Before the first edit, freeze the current artifact and record the material defects being fixed. The record can be concise, but it must be specific enough to re-check later. Minimum fields per defect: target path (or artifact id) + line range or anchor + one-sentence defect description. Without these, a later pass cannot verify whether the original defect was actually fixed.
- After each material edit, run another review focused on whether the original severe defects were fixed, whether the edit introduced new material defects, and whether the artifact still satisfies its stated trigger, boundary, output, and validation rules.
- Continue only while the review finds material defects that could cause wrong invocation, unsafe tool use, false claims, non-executable workflow, contradictory instructions, or likely rework.
- Stop when remaining points are wording preference, example coverage, formatting, optional expansion, or low-value polish that does not undermine execution. Report this as `未发现新的实质问题`, not as proof that the artifact is perfect.
- If the same concern repeats across two passes without a concrete new fix, classify it as an accepted residual risk or non-issue instead of spinning.

Review intensity:

- `Light`: compact pass. Use when the user wants quick but sharper thinking.
- `Standard`: default for important work.
- `Intensive`: use when the user asks for deep, complete, exhaustive, strict, or high-stakes scrutiny, or accepts higher token cost.

The Skill name `structured-review` describes the method, not the amount of work. Default to `Standard` for important work unless the user asks for deep or exhaustive scrutiny, the stakes justify it, or the user accepts higher token cost.
Treat `深度`, `深度review`, `深度审查`, `仔细完整`, `严格审查`, `完整`, `穷尽`, `不计成本`, `不怕耗 token`, `高风险`, `高 stakes`, deep review, complete, exhaustive, full, high-stakes, no-shortcuts, or higher-cost scrutiny as intensity signals for `Intensive`.

Intensity selection examples:

- `sr-review 下这个 Skill`: trigger this skill, usually `Standard`.
- `structured-review 下这个 Skill`: trigger this skill, usually `Standard`.
- `结构化review下这次普通代码改动`: trigger this skill, use the ordinary code review adapter, usually `Standard`.
- `深度/完整/穷尽/不计成本地 structured review 这个方案`: trigger through Serious Artifact Review Invocation and choose `Intensive`.
- `帮我减少返工`: no trigger unless a concrete non-trivial artifact or review target is present.
- `红队下这个变量名`: no trigger unless the user explicitly names `structured-review`.
- `structured review 看下这句话`: no unconditional trigger; answer lightly unless there is a concrete non-trivial artifact.
- `结构化评审这个大方案`: trigger through Serious Artifact Review Invocation or Artifact Review Context only if the plan is concrete and non-trivial.
- `review 并修这个本地 Skill`: choose `Revision`; freeze findings before editing and re-check them after the change.
- pasted artifact plus a file path: declare the primary target or compare cheaply before reviewing.

Internal phase checklist:

| Task | Light | Standard | Intensive |
|---|---|---|---|
| Design | 0, 1, 2, 5, 7 | 0, 1, 2, 3-core, 5, 7, 8-if-needed, 9 | 0, 1, 2, 3-core+optional, 4, 5, 6, 7, 8-consider, 9-if-needed |
| Review | 0, 2, 7 | 0, 1-freeze, 2, 3-core, 5, 7, 8-if-needed | 0, 1-freeze, 2, 3-core+optional, 4, 5, 7, 8-consider, 9-if-needed |
| Revision | 0, 2, 5, 7 | 0, 1-freeze, 2, 3-core, 5, 7, 8-if-needed | 0, 1-freeze, 2, 3-core+optional, 4, 5, 6, 7, 8-consider, 9-if-needed |

Use this checklist to decide what to inspect internally. It is not a required output outline.
Never emit every phase by default. Mention only the phases whose results are useful to the user, and fold low-value phases into tighter sections when that preserves the finding and recommendation.
For `Light`, keep the answer compact: phase 2 should usually contain no more than three findings.

## Core vs Optional Phases

Core phases for `Standard` and `Intensive` runs:

- `0`: frame the task or review target
- `1`: create candidates for design, or freeze the supplied artifact for review/revision
- `2`: simulated fresh-context scrutiny
- `5`: repair direction, change plan, or modification summary
- `7`: final recommendation or final artifact

For `Light` review, phase 1 is implicit in phase 2 and phase 5 is folded into phase 7.
For `Light` revision, phase 1 is implicit in phase 2.

Optional:

- `3`: add multi-perspective review when the work is complex, cross-functional, or ambiguous
- `4`: add risk register when the change is irreversible, operationally risky, costly, or high stakes
- `6`: add second review only after a material rewrite or decision change
- `8`: add external review package when independent review is valuable
- `9`: add minimal next step when the work is large or the user needs execution guidance

In `Standard`, phase 8 is optional but recommended when the artifact is hard to reverse, affects more than one person or team, commits meaningful time or money, or will be used as an approval basis.

For routine `Standard` output, prefer a compact shape unless the artifact needs a fuller audit:

- frame: one short paragraph or 2-4 bullets
- fresh-context findings: the highest-value issues first
- repair direction: grouped as must-fix, later, or accepted risk
- final recommendation: one clear conclusion

Do not emit separate headings for every selected phase when a tighter answer carries the same information.
For artifact review tasks, final output should lead with phase 2 findings. Phase 0 and phase 1 may be internal or reduced to one short scope line unless the scope itself is disputed.

## Ordinary Code Review Adapter

Use this adapter only when the review target is an ordinary code diff, commit, or PR and the user explicitly invoked this skill.

Keep the host code-review contract:

- lead with findings ordered by severity
- include concrete file and line references when available
- keep summaries secondary and brief
- mention missing tests or residual risk after findings
- do not print phase headings, phase tables, risk registers, or the full structured-review skeleton unless the user explicitly asks for them

Internally apply phase 2 and, when useful, phase 3 to look harder for behavioral regressions, missed edge cases, contract drift, test gaps, and rollback risk.
The first concrete finding may satisfy the anti-sycophancy rule; do not add a separate `最严重的一个缺陷` preface if it would duplicate or disrupt the host findings-first format.

## Operating Rules

- Default to Chinese unless the user asks otherwise.
- Be direct, practical, and specific.
- Do not flatter the artifact before identifying real issues.
- Do not invent missing context, facts, citations, constraints, or validation.
- Mark assumptions explicitly.
- Treat unclear goals, missing success criteria, and unstated constraints as defects.
- Prefer a few strong findings over many weak comments.
- Avoid fixed long templates when the task does not need them.
- Use tables only when they improve comparison, triage, or risk handling.
- If facts may be stale or external, mark them as needing verification.
- Stop once remaining issues are minor or further review would create noise.

## Anti-Sycophancy Rule

In phase 2, or in the equivalent review-findings section for host code-review output, the first substantive finding must identify the most serious defect.

For artifact-review output, use this sentence form:

```markdown
最严重的一个缺陷：...
```

Do not put a summary, praise, reassurance, or positive evaluation before the findings section.

For host code-review output, the top severity finding can satisfy this rule without using that exact sentence form.

If no serious defect is found, do not invent one. For artifact-review output, use:

```markdown
最严重的一个缺陷：未发现明确严重缺陷；最高价值改进是...
```

For host code-review output with no findings, say that clearly and mention the highest residual test gap or risk.
Then list the strongest remaining improvement or risk. If even that is minor, say so plainly.
This rule controls the first review-findings section, not necessarily the first line of the entire assistant response when higher-priority host instructions require a different wrapper.

## Phase 0: Frame

For design:

- goal
- non-goals
- known context
- constraints
- assumptions
- deliverable
- success criteria

For review or revision:

- artifact type
- claimed goal
- intended reader or implementer
- visible scope
- missing or ambiguous scope
- review standard
- assumptions used for the review

Keep this short. It is context control, not a preface.

## Phase 1: Candidate Scan or Frozen Artifact

For `Design`, list at least two candidate approaches by default, even briefly.

For each candidate:

- one-line idea
- main advantage
- main risk

Then choose one and explain why. This prevents the first plausible idea from becoming the only idea.
If there is only one real option because of a hard constraint, write `替代方案考量：无 — 原因：...` instead of inventing a strawman option.

For `Review` or `Revision`, freeze the supplied artifact:

- review only what is present or directly implied
- do not repair while reading
- do not fill gaps with the user's likely intent
- mark missing context as a document defect when it affects execution or review

## Phase 2: Simulated Fresh-Context Scrutiny

This is a same-thread simulation, not true context isolation.

Review the frozen artifact or chosen solution as if only that artifact existed.
In `Light` review or revision, first mentally freeze the artifact: read it as-is, do not complete the author's intent, and treat execution-critical gaps as defects.

For artifact-review output, start the findings section with:

```markdown
最严重的一个缺陷：...
```

For host code-review output, use the Ordinary Code Review Adapter instead of forcing this exact phrase.
If no serious defect exists, use the no-fabrication fallback from the Anti-Sycophancy Rule.

Then identify the highest-value issues:

- unclear goal
- undefined terms
- hidden assumptions
- missing inputs
- non-executable steps
- unverifiable success criteria
- scope drift
- missing rollback or repair path
- places another implementer could interpret differently

When reviewing prompts, Skills, process docs, or operating rules, also check:

- whether trigger rules are too broad or too narrow
- whether tool/file/network boundaries are explicit
- whether naming matches how users will actually invoke it
- whether mandatory output shapes force fake findings or unnecessary sections
- whether claimed capabilities depend on context the current environment may not provide

For artifact review tasks, a useful output shape is:

```markdown
## 新上下文审查

最严重的一个缺陷：...

| 问题 | 执行风险 | 返工风险 | 证据/位置 | 建议 |
|---|---|---|---|---|
| ... | 低 / 中 / 高 | 低 / 中 / 高 | ... | ... |

缺失信息：
- ...
```

Use the risk columns for quick scanning:

- `执行风险`: whether the issue blocks or destabilizes immediate execution.
- `返工风险`: whether the issue is likely to cause redesign, reimplementation, or changed conclusions later.
- Use text levels: `低`, `中`, and `高`. Visual markers or colors are optional, but do not rely on them for meaning.

## Phase 3: Multi-Perspective Review

Use three core roles first:

- `Goal Keeper`: checks goal fit, priorities, success criteria, overengineering, underengineering
- `Implementer`: checks inputs, sequence, dependencies, workload, handoff, executability
- `Red Team`: checks failure modes, rework traps, optimistic assumptions, hidden risk

Add optional roles only when relevant:

- `User / Reader`: for product, docs, UX, adoption, or audience-sensitive work
- `Skeptical Expert`: for technically deep or domain-specific work
- `Project Manager / Validator`: for multi-person delivery, deadlines, milestones, or acceptance

Avoid repeating the same finding under multiple roles unless the consequence differs.

## Phase 4: Risk Decisions

Use this phase when decisions are high stakes, costly, hard to reverse, or operationally risky.

Avoid fake precision. Do not use probability and impact scoring unless real evidence exists.

Prefer concrete fields:

```markdown
| 风险 | 是否阻断交付 | 可逆性 | 触发后是否还有修复时间 | 应对方式 | 当前决定 |
|---|---|---|---|---|---|
| ... | 是/否 | 可逆/部分可逆/不可逆 | 有/没有 | ... | 修复/接受/验证/延后 |
```

Every important risk must become one of:

- fix now
- monitor later
- explicitly accept
- verify externally
- defer with reason

## Phase 5: Repair Direction or Change Summary

Do not duplicate the final artifact here.

For design:

- explain what changed after review
- list the chosen fixes
- name rejected suggestions and why they were rejected

For review-only:

- `必须先改`
- `可以后改`
- `需要补充的信息`
- `可以接受的风险`

For revision:

- provide a diff-style change summary
- then put the complete revised artifact in phase 7 if the user requested a rewrite

## Phase 6: Second Review

Use only after material changes. For iterative review-and-fix requests, repeat phase 5 and phase 6 until the Iterative review-and-fix stopping rule says no material defects remain.
Material changes include changes to the goal, scope, critical steps, verification strategy, risk handling, or acceptance criteria.
Wording-only edits, formatting, or reordered paragraphs are not material changes.

Focus on:

- whether the original severe defects were fixed
- remaining high-risk gaps
- newly introduced problems
- whether execution should proceed

Do not repeat phase 2 with new headings.

## Phase 7: Final Recommendation or Final Artifact

Produce the useful end state:

- for design: final plan or implementation checklist
- for review: approval recommendation and required fixes
- for revision: final rewritten artifact, if requested

Avoid duplicating phase 5. If phase 5 already contains the change summary, phase 7 should contain the final artifact or final recommendation.

Review conclusion options:

- `通过`
- `修改后通过`
- `暂不通过`
- `可以执行，但需接受以下风险`

Use `可以执行，但需接受以下风险` only when the remaining risks can be explicitly accepted by a named owner or decision-maker.
If no one can clearly own the remaining risk, use `修改后通过` or `暂不通过` instead.

## Phase 8: External Review Package

This is the strongest review step because it can be run in a genuinely separate context.

When independent review would materially reduce approval risk, recommend using this package before final approval.
In `Standard`, consider this phase when the artifact is hard to reverse, affects more than one person or team, commits meaningful time or money, or will be used as an approval basis.

Do not claim the package has been run unless it was actually executed in a separate context. In normal same-thread work, only provide the package for the user or another model/chat to run.
A subagent / sub-session that starts cold satisfies "separate context" when the environment exposes a callable tool and the task can be safely delegated. If the user forbids subagents, the environment does not expose such a tool, delegation would be unsafe, or no actual run happened, do not imply one was used; write that the package is ready to run elsewhere.

```markdown
请作为一个完全不了解前文的新上下文，审查下面这份方案或文档。

不要顺着作者意图补全缺失信息。
凡是需要依赖隐含背景的地方，都视为文档缺陷。

请重点检查：
1. 目标是否清楚
2. 范围是否合理
3. 步骤是否可执行
4. 假设是否危险
5. 是否会导致返工
6. 是否有遗漏
7. 是否存在更简单方案

[粘贴最终方案/文档]

请输出：
1. 最严重的一个缺陷
2. 最大的 5 个问题
3. 最可能导致返工的 5 个风险
4. 必须补充的信息
5. 最关键的 3 处修改方向，不要重写全文
6. 是否建议执行
```

## Phase 9: Minimal Next Step

End with the smallest useful next action when execution may otherwise stall.

Examples:

- run one validation command
- ask one missing question
- write one missing section
- verify one external dependency
- split one risky step into a reversible checkpoint

## Worked Mini Example

User asks: `审查这个方案：用一个周任务批量回填用户等级，失败了下周再跑。`

Good shape:

```markdown
## 新上下文审查

最严重的一个缺陷：方案没有定义幂等、断点和回滚边界，失败后“下周再跑”可能重复写入或掩盖部分失败。

| 问题 | 执行风险 | 返工风险 | 证据/位置 | 建议 |
|---|---|---|---|---|
| 缺少幂等键和处理状态 | 高 | 高 | 只说失败下周再跑 | 增加批次号、处理状态、重跑规则 |

审查范围：批量回填方案；标准是能否安全执行、失败后能否恢复、结果能否验证。

## 修复建议
- 必须先改：增加 dry-run、分批 checkpoint、失败重跑策略、结果校验 SQL。
- 可以后改：补充监控告警和人工处理 runbook。

## 最终审查报告
结论：修改后通过。当前版本不建议直接执行。
```

Anti-pattern: starting phase 2 with `整体思路合理，但...` violates the anti-sycophancy rule.

For a `Revision` request such as `review 并修这个 Skill 文件`, the good shape is:

```markdown
## 新上下文审查
最严重的一个缺陷：...

| 问题 | 执行风险 | 返工风险 | 证据/位置 | 建议 |
|---|---|---|---|---|
| ... | ... | ... | path:line | ... |

## 修复计划
- 必须先改：...

[执行 Edit/Write 修改文件]

## 第二轮 review
- 原缺陷 N 是否消除：...
- 是否引入新缺陷：...

## 修复项汇总
| # | 位置 | 缺陷 | 修复 |
|---|---|---|---|
```

For an `Iterative` review-and-fix, repeat `修复 → 第 N 轮 review` until the stopping rule fires, then close with the cumulative 修复项汇总.

## Output Style

The output should match the task size.

For small review tasks, 3-5 short sections are enough.
For high-stakes work, inspect the selected phases from the internal checklist, then output only the sections needed to carry the findings, decision, and next action.
Never emit a fixed 9-section skeleton unless the user explicitly asks for the full process.
Once phase 7 gives a clear conclusion and there are no new material findings, stop; do not append phase 8 or 9 just to complete the structure.

Do not invoke this skill for a small direct question such as `这个变量名可以吗？` unless one of the explicit-naming forms in `Trigger Rules § A` is used. Phrases such as `红队`, `多角度`, or `新上下文` still need a concrete, non-trivial target. When explicit naming is used on a small question, the skill is triggered but defaults to `Light` intensity per the Task Type and Intensity rules.
