# th-skill

Personal AI assistant skill backups.

This repository is the source of truth for custom skills shared across local
Codex and Claude environments.

## Layout

```text
skills/
  <skill-name>/SKILL.md
scripts/
  install-codex.sh
  install-claude.sh
```

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

