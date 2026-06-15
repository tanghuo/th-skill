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

## Audit Assets

- `skills/audit/`: global entry wrapper. It expects a repo-local
  `.local/review/` prompt library.
- `templates/audit-review-v2/`: generic repo-local review prompt template.
  Copy it into a repository's `.local/review/` and replace placeholders with
  real entry points, state objects, schema paths, runtime constraints, and run
  history.
- `examples/`: optional local snapshots of repo-specific audit prompt libraries.
  This directory is gitignored because those snapshots may contain private
  architecture notes, entry maps, business semantics, and run history.
