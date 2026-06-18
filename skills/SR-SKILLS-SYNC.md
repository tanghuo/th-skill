# SR Skills Sync (canonical)

Single source of truth for how the `sr-*` skill family is propagated across its copies on
this machine. This file lives only in the Codex working copy; both runtimes read it at
this Codex path. It is not mirrored.

## 1. Copies and roles

There are three copies; they are not peers:

- **Codex working copy — `~/.codex/skills/`**: the canonical EDIT surface. Every change
  is made here first.
- **Claude mirror — `~/.claude/skills/`**: a remapped mirror of the Codex copy (different
  tool names / paths). Never edited directly; produced from Codex via §2.
- **`th-skill` git repo — `~/GolandProjects/th-skill`** (`github.com/tanghuo/th-skill`):
  the versioned backup / publish layer. Stores skills in **Codex flavor** under
  `skills/`. Receives a copy of the Codex working copy, then commit & push. Its
  `scripts/install-*.sh` are for bootstrapping a fresh machine, not the day-to-day edit
  path.

Propagation for one change: **edit Codex → remap to Claude (§2) → copy Codex-flavor into
`th-skill/skills/` → commit & push.**

> `th-skill/README.md` calls itself "source of truth". Read that as the durable, versioned
> backup; the live EDIT canonical is the Codex working copy.

## 2. Mapping table (Codex → Claude)

Apply these when mirroring Codex → Claude; keep everything else identical.

- absolute path prefix `/Users/chenxitang/.codex/skills/...` → `/Users/chenxitang/.claude/skills/...`,
  **but only for companion-skill read references** (`.../sr-*/SKILL.md`). The
  back-reference to this file (`~/.codex/skills/SR-SKILLS-SYNC.md`) is an intentional
  Codex-canonical pointer and is the same in both copies — do not remap it.
- `apply_patch` → the Edit tool (new files → the Write tool)
- `explorer` subagent + `fork_context=false` → Agent tool, subagent_type `Explore` (read-only)
- clean-context `worker` → Agent tool, subagent_type `general-purpose`; "forked workspace" → `isolation: "worktree"`

The install scripts must cover every mapping that appears in current skill bodies; when a
new mapping starts appearing in a skill, update the Claude installer in the same change.

**Exemptions — do NOT remap, and do NOT mirror to Claude:**

- `SR-SKILLS-SYNC.md` (this file) — Codex-only; both runtimes read this Codex path.
- Non-`SKILL.md` reference drafts under a skill (e.g. `*/references/*.md`, such as
  `sr-task-runner/references/sr-subthread-experimental.md`) — Codex-only design notes, not
  executable skills.

**Exemption — copy byte-identical (no remap), but still mirror:**

- Host-agnostic skills whose own `SKILL.md` declares byte-identical (e.g. `sr-expert`).
  Their only `.codex` reference is the back-ref above, which §2 already preserves, so the
  remap is a no-op for them.

## 3. Managed skills

`sr-review`, `sr-task-loop`, `sr-task-runner`, `sr-plan-split`, `sr-design-gate`,
`sr-split-ready`, `sr-worktree-review-fix-loop`, `sr-expert` (byte-identical exemption).

## 4. Checklist (run after editing any sr-* skill)

- [ ] change landed in the Codex working copy first
- [ ] mirrored to the Claude copy with the §2 mappings (skip the §2 exemptions)
- [ ] copied into `th-skill/skills/` (Codex flavor), committed & pushed
- [ ] no repo-specific names leaked into a global skill (table/column names, repo paths,
      money/timezone rules belong in repo profile / project memory / a task's `Validation`
      field, never in the skill body)
- [ ] Codex and Claude copies still agree except for the mapped lines

## 5. Install scripts (fresh-machine bootstrap only)

- `th-skill/scripts/install-codex.sh`: raw `rsync` of `th-skill/skills/` (Codex flavor) →
  `~/.codex/skills`. Correct as-is.
- `th-skill/scripts/install-claude.sh`: `rsync` → `~/.claude/skills` excluding the
  Codex-only files (§2 exemptions), then applies the §2 remaps. A raw `rsync` would push
  Codex flavor into Claude and is wrong. The script covers the path, `apply_patch`, and
  subagent mappings currently in use; if a new mapping kind from §2 appears in skill
  bodies, extend the script too.

## 6. Discoverability

Each managed `sr-*` `SKILL.md` carries a back-reference to this file (a short
"Skill Maintenance" note), so an agent editing the skill naturally reads this convention.
Adding a new managed skill means adding that back-reference too.
