# SR Driver Template

Repo-local state driver for `sr-*` agent workflows.

This template installs `.local/sr-run.sh` into a target repository. The driver
tracks workflow and phase, prints the next required skill/action, and keeps
agents from resuming by memory alone.

Supported workflows:

- `worktree-review`
- `task-loop`
- `task-runner`
- `feature-dev`

Scope:

- record one active workflow state in `.local/sr-driver/state.env`
- print next actions for the agent
- check cheap phase evidence where possible, such as sr-gate freeze/check state
- support explicit block/done/clear operations

Non-goals:

- replacing `sr-*` skills
- doing implementation, review, or business judgment
- proving review quality
- providing durable multi-worker orchestration

Typical agent flow:

```bash
.local/sr-run.sh start worktree-review --label room-fix
.local/sr-run.sh next
# agent follows the indicated sr skill/action
.local/sr-run.sh advance review --note "target frozen"
```

Install into a repository:

```bash
/Users/chenxitang/GolandProjects/th-skill/scripts/install-sr-driver.sh /path/to/repo
```
