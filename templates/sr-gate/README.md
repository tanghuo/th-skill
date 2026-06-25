# SR Gate Template

Repo-local commit hygiene gate for `sr-*` agent workflows.

This template installs `.local/srctl.sh` into a target repository and adds a git
`pre-commit` hook that runs `.local/srctl.sh verify`.

Scope:

- freeze the allowed commit target
- require staged files to stay inside the frozen target
- bind a passing validation command to the current staged diff hash
- run cheap pre-commit checks without running heavy tests inside the hook

Non-goals:

- proving that review happened
- replacing agent judgment
- managing resumable workflow state
- preventing deliberate `--no-verify` bypasses

Typical agent flow:

```bash
.local/srctl.sh freeze <label>
# agent reviews, fixes, and stages the coherent change set
.local/srctl.sh check -- <validation command>
git commit -m "..."
```

Install into a repository:

```bash
/Users/chenxitang/GolandProjects/th-skill/scripts/install-sr-gate.sh /path/to/repo
```
