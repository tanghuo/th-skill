#!/usr/bin/env bash
set -euo pipefail

# Claude stores a REMAPPED mirror of the Codex-flavored skills in this repo.
# A raw rsync would push Codex tool names / paths into Claude and is wrong.
# See skills/SR-SKILLS-SYNC.md §2 for the canonical mapping rules.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${HOME}/.claude/skills"

mkdir -p "${target}"

# Remove stale copies of repo-owned paths that are excluded from the Claude mirror.
# `rsync --exclude` skips new copies but does not delete old target files.
rm -f "${target}/SR-SKILLS-SYNC.md"
find "${repo_root}/skills" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
  rm -rf "${target}/$(basename "${skill_dir}")/references"
done

# Codex-only artifacts are excluded from the Claude mirror (SR-SKILLS-SYNC.md §2 exemptions):
#   - SR-SKILLS-SYNC.md           : canonical, read at its Codex path by both runtimes
#   - */references/*.md           : Codex-only design drafts, not executable skills
rsync -a --exclude 'SR-SKILLS-SYNC.md' --exclude 'references/' "${repo_root}/skills/" "${target}/"

# Apply the §2 token remaps. Covers the mappings currently used in skill bodies:
#   - companion read references  .codex/skills/sr-*/SKILL.md -> .claude/...
#     (the SR-SKILLS-SYNC.md back-reference is an intentional Codex pointer; left untouched)
#   - the manual-edit instruction line: apply_patch -> Edit/Write tool
#   - Codex subagent terms -> Claude Agent tool terms
# If a new mapping kind from §2 starts appearing in skill bodies, extend this block.
find "${target}" -name '*.md' -type f -print0 | while IFS= read -r -d '' f; do
  sed -i '' \
    -e 's#/Users/chenxitang/\.codex/skills/\(sr-[a-z-]*/SKILL\.md\)#/Users/chenxitang/.claude/skills/\1#g' \
    -e 's#For manual edits, use `apply_patch`.#For manual edits, use the Edit tool (or the Write tool for new files).#g' \
    -e 's#use `apply_patch` for manual edits#use the Edit tool for manual edits#g' \
    -e 's#spawn one `explorer` subagent with `fork_context=false`#spawn one read-only review subagent via the Agent tool (subagent_type `Explore`)#g' \
    -e 's#do not set `model`; let it inherit the current model#let it inherit the current model (Agent tool default)#g' \
    -e 's#For bug fixing, use a clean-context `worker` when all of these are true:#For bug fixing, use a clean-context implementation subagent (Agent tool, subagent_type `general-purpose`) when all of these are true:#g' \
    -e 's#the worker is told to edit files directly in its forked workspace and list changed files in its final answer#the worker is told to edit files directly and list changed files in its final answer; use `isolation: "worktree"` when it needs an isolated copy of the repo#g' \
    "$f"
done

echo "Installed + remapped skills to ${target}"
