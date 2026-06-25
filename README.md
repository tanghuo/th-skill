# th-skill

Personal AI assistant skill backups.

This repository is the source of truth for custom skills shared across local
Codex and Claude environments.

## Layout

```text
skills/
  <skill-name>/SKILL.md
templates/
  <template-name>/
examples/
  <example-name>/
scripts/
  install-codex.sh
  install-claude.sh
  install-sr-gate.sh
  install-sr-driver.sh
```

- `skills/`: installable global skills.
- `templates/`: reusable starting points for new repositories or workflows.
- `examples/`: local-only ignored snapshots from real repositories, useful as
  private reference material but not committed.

## Install

Install into Codex:

```bash
scripts/install-codex.sh
```

Install into Claude:

```bash
scripts/install-claude.sh
```

The install scripts copy `skills/*` into the target local skill directory. They
do not copy sessions, caches, history, auth state, or other local app data.

Install the repo-local SR commit hygiene gate into a target repository:

```bash
scripts/install-sr-gate.sh /path/to/repo
```

This copies `templates/sr-gate/srctl.sh` to `.local/srctl.sh` in the target repo
and installs a git `pre-commit` hook that verifies frozen target membership,
staged-diff hash-bound checks, and cheap commit hygiene checks.

Install the repo-local SR workflow state driver into a target repository:

```bash
scripts/install-sr-driver.sh /path/to/repo
```

This copies `templates/sr-driver/sr-run.sh` to `.local/sr-run.sh` in the target
repo. The driver records the active `sr-*` workflow phase and prints the next
skill/action for the agent.

## Audit Assets

- `skills/audit/`: global entry wrapper. It expects a repo-local
  `.local/review/` prompt library.
- `templates/audit-review-v2/`: generic repo-local review prompt template.
  Copy it into a repository's `.local/review/` and replace placeholders with
  real entry points, state objects, schema paths, runtime constraints, and run
  history.
- `templates/sr-gate/`: repo-local commit hygiene gate used by `sr-task-loop`
  and `sr-worktree-review-fix-loop` when installed.
- `templates/sr-driver/`: repo-local state driver for `worktree-review`,
  `task-loop`, `task-runner`, and `feature-dev` workflows.
- `examples/`: optional local snapshots of repo-specific audit prompt libraries.
  This directory is gitignored because those snapshots may contain private
  architecture notes, entry maps, business semantics, and run history.
