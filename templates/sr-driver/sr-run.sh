#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT_DIR}" ]]; then
  echo "sr-run: must run inside a git repository" >&2
  exit 1
fi
cd "${ROOT_DIR}"

DRIVER_DIR=".local/sr-driver"
STATE_FILE="${DRIVER_DIR}/state.env"
HISTORY_FILE="${DRIVER_DIR}/history.md"
LOCK_DIR="${DRIVER_DIR}/.lock"

usage() {
  cat <<'EOF'
Usage:
  .local/sr-run.sh start <worktree-review|task-loop|task-runner|feature-dev> [target] [--label <text>]
  .local/sr-run.sh status
  .local/sr-run.sh next
  .local/sr-run.sh advance <phase> [--note <text>]
  .local/sr-run.sh block <reason>
  .local/sr-run.sh done [--note <text>]
  .local/sr-run.sh clear

V1 state driver:
  - tracks the active sr workflow and phase
  - prints the next skill/action for the agent
  - checks cheap phase evidence where possible
  - does not replace sr-* skills, review judgment, or implementation work
EOF
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

release_lock() {
  if [[ "${SRRUN_LOCKED:-0}" == "1" ]]; then
    rmdir "${LOCK_DIR}" 2>/dev/null || true
  fi
}

acquire_lock() {
  mkdir -p "${DRIVER_DIR}"
  local i
  for i in {1..100}; do
    if mkdir "${LOCK_DIR}" 2>/dev/null; then
      SRRUN_LOCKED=1
      trap release_lock EXIT
      return 0
    fi
    sleep 0.1
  done
  echo "sr-run: another sr-run command is still running; lock=${LOCK_DIR}" >&2
  exit 1
}

require_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    echo "sr-run: no active workflow; start with .local/sr-run.sh start <workflow>" >&2
    exit 1
  fi
}

load_state() {
  require_state
  # shellcheck disable=SC1090
  source "${STATE_FILE}"
}

write_state() {
  mkdir -p "${DRIVER_DIR}"
  {
    printf 'WORKFLOW=%q\n' "${WORKFLOW:-}"
    printf 'TARGET=%q\n' "${TARGET:-}"
    printf 'PHASE=%q\n' "${PHASE:-}"
    printf 'LABEL=%q\n' "${LABEL:-}"
    printf 'CREATED_AT=%q\n' "${CREATED_AT:-}"
    printf 'UPDATED_AT=%q\n' "${UPDATED_AT:-}"
    printf 'BLOCKER=%q\n' "${BLOCKER:-}"
    printf 'NOTE=%q\n' "${NOTE:-}"
  } > "${STATE_FILE}"
}

append_history() {
  local event="$1"
  mkdir -p "${DRIVER_DIR}"
  if [[ ! -f "${HISTORY_FILE}" ]]; then
    printf '# sr-run history\n\n' > "${HISTORY_FILE}"
  fi
  printf -- '- %s %s\n' "$(now_utc)" "${event}" >> "${HISTORY_FILE}"
}

parse_note_args() {
  NOTE_ARG=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --note)
        if [[ $# -lt 2 ]]; then
          echo "sr-run: --note requires text" >&2
          exit 1
        fi
        NOTE_ARG="$2"
        shift 2
        ;;
      *)
        echo "sr-run: unknown argument: $1" >&2
        exit 1
        ;;
    esac
  done
}

phase_allowed() {
  local workflow="$1"
  local phase="$2"
  case "${workflow}:${phase}" in
    worktree-review:freeze|worktree-review:review|worktree-review:stage-check|worktree-review:rereview|worktree-review:commit|worktree-review:done|worktree-review:blocked) return 0 ;;
    task-loop:freeze|task-loop:implement|task-loop:stage-check|task-loop:review|task-loop:update-task|task-loop:commit|task-loop:done|task-loop:blocked) return 0 ;;
    task-runner:inventory|task-runner:run-ready|task-runner:checkpoint|task-runner:final-review|task-runner:done|task-runner:blocked) return 0 ;;
    feature-dev:design|feature-dev:design-review|feature-dev:split-ready|feature-dev:split|feature-dev:task-runner|feature-dev:done|feature-dev:blocked) return 0 ;;
    *) return 1 ;;
  esac
}

srctl_status_value() {
  local key="$1"
  [[ -x .local/srctl.sh ]] || return 1
  local status
  status="$(.local/srctl.sh status)"
  awk -F: -v key="${key}" '$1 == key { sub(/^ /, "", $2); print $2; exit }' <<< "${status}"
}

check_phase_evidence() {
  local workflow="$1"
  local phase="$2"
  case "${workflow}:${phase}" in
    worktree-review:review|task-loop:implement)
      if [[ -x .local/srctl.sh ]]; then
        local freeze
        freeze="$(srctl_status_value freeze || true)"
        if [[ "${freeze}" != "present" ]]; then
          echo "sr-run: cannot advance to ${phase}: srctl freeze is missing" >&2
          echo "sr-run: run .local/srctl.sh freeze <label>, or refresh with an explicit reason" >&2
          exit 1
        fi
      fi
      ;;
    worktree-review:rereview|task-loop:review)
      if [[ -x .local/srctl.sh ]]; then
        local check
        check="$(srctl_status_value check || true)"
        if [[ "${check}" != "present" ]]; then
          echo "sr-run: cannot advance to ${phase}: srctl check-pass is missing" >&2
          echo "sr-run: stage the coherent change set, then run .local/srctl.sh check -- <validation command>" >&2
          exit 1
        fi
      fi
      ;;
  esac
}

print_header() {
  echo "workflow=${WORKFLOW}"
  echo "target=${TARGET:-<none>}"
  echo "phase=${PHASE}"
  echo "label=${LABEL:-<none>}"
}

next_worktree_review() {
  case "${PHASE}" in
    freeze)
      cat <<EOF
Next:
- Resolve and inspect the current worktree target.
- If .local/srctl.sh exists, run: .local/srctl.sh freeze ${LABEL:-worktree-review}
- Then run: .local/sr-run.sh advance review --note "target frozen"
- Use skill: sr-worktree-review-fix-loop
EOF
      ;;
    review)
      cat <<'EOF'
Next:
- Use sr-worktree-review-fix-loop to review the frozen current diff.
- Fix accepted material findings.
- Stage only the coherent change set.
- Then run: .local/sr-run.sh advance stage-check --note "repair staged"
EOF
      ;;
    stage-check)
      cat <<'EOF'
Next:
- Run the validation gate for the staged coherent change set:
  .local/srctl.sh check -- <focused validation command>
- Then run: .local/sr-run.sh advance rereview --note "check passed"
EOF
      ;;
    rereview)
      cat <<'EOF'
Next:
- Re-review the repair diff and validation evidence.
- If no material issues remain, run: .local/sr-run.sh advance commit --note "clean"
- If more fixes are needed, fix them, stage, rerun srctl check, and stay/return to rereview.
EOF
      ;;
    commit)
      cat <<'EOF'
Next:
- Commit normally. The git pre-commit hook should run .local/srctl.sh verify.
- Do not bypass with --no-verify unless explicitly instructed and explain why.
- Then run: .local/sr-run.sh done --note "committed"
EOF
      ;;
    done) echo "Next: workflow is done." ;;
    blocked) echo "Next: resolve blocker or clear/start a new workflow." ;;
  esac
}

next_task_loop() {
  case "${PHASE}" in
    freeze)
      cat <<EOF
Next:
- Read the task file and source context: ${TARGET:-<task.md>}
- Mark the task in_progress when appropriate.
- If .local/srctl.sh exists, run: .local/srctl.sh freeze ${LABEL:-task-loop}
- Then run: .local/sr-run.sh advance implement --note "task frozen"
- Use skill: sr-task-loop
EOF
      ;;
    implement)
      cat <<'EOF'
Next:
- Implement the minimum coherent task change using sr-task-loop rules.
- Stage only the coherent task change set.
- Then run: .local/sr-run.sh advance stage-check --note "implementation staged"
EOF
      ;;
    stage-check)
      cat <<'EOF'
Next:
- Run the task validation gate:
  .local/srctl.sh check -- <task validation command>
- Then run: .local/sr-run.sh advance review --note "check passed"
EOF
      ;;
    review)
      cat <<'EOF'
Next:
- Run task-local spec review and code review.
- Fix material findings and rerun srctl check when staged content changes.
- When clean, run: .local/sr-run.sh advance update-task --note "task review clean"
EOF
      ;;
    update-task)
      cat <<'EOF'
Next:
- Update the task file status/completion log.
- Stage the task file if it belongs to the same coherent task change.
- Rerun srctl check if staged content changed.
- Then run: .local/sr-run.sh advance commit --note "task updated"
EOF
      ;;
    commit)
      cat <<'EOF'
Next:
- Commit normally. The git pre-commit hook should run .local/srctl.sh verify.
- Then run: .local/sr-run.sh done --note "task committed"
EOF
      ;;
    done) echo "Next: workflow is done." ;;
    blocked) echo "Next: resolve blocker or clear/start a new workflow." ;;
  esac
}

next_task_runner() {
  case "${PHASE}" in
    inventory)
      cat <<EOF
Next:
- Use sr-task-runner to inventory task directory/list: ${TARGET:-<tasks>}
- Identify ready tasks, blockers, checkpoints, and safe execution mode.
- Then run: .local/sr-run.sh advance run-ready --note "inventory ready"
EOF
      ;;
    run-ready)
      cat <<'EOF'
Next:
- Use sr-task-runner to execute the next ready task(s), delegating to sr-task-loop as needed.
- Refresh inventory after each Host-completed task.
- Advance to checkpoint when a checkpoint boundary is reached, or final-review when selected tasks complete.
EOF
      ;;
    checkpoint)
      cat <<'EOF'
Next:
- Run checkpoint integration review for completed ready-set/phase.
- Fix or create blocking tasks for material composition issues.
- Then advance back to run-ready or final-review.
EOF
      ;;
    final-review)
      cat <<'EOF'
Next:
- Run final integration review over the selected task batch.
- If clean, run: .local/sr-run.sh done --note "runner final review clean"
EOF
      ;;
    done) echo "Next: workflow is done." ;;
    blocked) echo "Next: resolve blocker or clear/start a new workflow." ;;
  esac
}

next_feature_dev() {
  case "${PHASE}" in
    design)
      cat <<EOF
Next:
- Use sr-design-gate for the feature intent/target: ${TARGET:-<intent>}
- Produce or update a concrete design artifact.
- Then run: .local/sr-run.sh advance design-review --note "design drafted"
EOF
      ;;
    design-review)
      cat <<'EOF'
Next:
- Use sr-review to review the design artifact.
- Fix accepted material design issues.
- Then run: .local/sr-run.sh advance split-ready --note "design reviewed"
EOF
      ;;
    split-ready)
      cat <<'EOF'
Next:
- Use sr-split-ready to confirm the design is structured enough to split.
- If ready, run: .local/sr-run.sh advance split --note "split ready"
EOF
      ;;
    split)
      cat <<'EOF'
Next:
- Use sr-plan-split to create execution-ready task markdown files.
- Then run: .local/sr-run.sh advance task-runner --note "tasks created"
EOF
      ;;
    task-runner)
      cat <<'EOF'
Next:
- Start or continue sr-task-runner on the generated task directory.
- You may also start a separate driver run:
  .local/sr-run.sh start task-runner <task-dir>
EOF
      ;;
    done) echo "Next: workflow is done." ;;
    blocked) echo "Next: resolve blocker or clear/start a new workflow." ;;
  esac
}

cmd_start() {
  if [[ $# -lt 1 ]]; then
    usage >&2
    exit 1
  fi
  if [[ -f "${STATE_FILE}" ]]; then
    echo "sr-run: active workflow already exists; run status, done, block, or clear first" >&2
    exit 1
  fi

  local workflow="$1"
  shift
  local target=""
  local label=""

  if [[ $# -gt 0 && "$1" != "--label" ]]; then
    target="$1"
    shift
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --label)
        if [[ $# -lt 2 ]]; then
          echo "sr-run: --label requires text" >&2
          exit 1
        fi
        label="$2"
        shift 2
        ;;
      *)
        echo "sr-run: unknown argument: $1" >&2
        exit 1
        ;;
    esac
  done

  case "${workflow}" in
    worktree-review) PHASE="freeze"; label="${label:-worktree-review}" ;;
    task-loop)
      [[ -n "${target}" ]] || { echo "sr-run: task-loop requires <task.md>" >&2; exit 1; }
      PHASE="freeze"; label="${label:-task-loop}"
      ;;
    task-runner)
      [[ -n "${target}" ]] || { echo "sr-run: task-runner requires <task-dir-or-list>" >&2; exit 1; }
      PHASE="inventory"; label="${label:-task-runner}"
      ;;
    feature-dev) PHASE="design"; label="${label:-feature-dev}" ;;
    *) echo "sr-run: unknown workflow: ${workflow}" >&2; exit 1 ;;
  esac

  WORKFLOW="${workflow}"
  TARGET="${target}"
  LABEL="${label}"
  CREATED_AT="$(now_utc)"
  UPDATED_AT="${CREATED_AT}"
  BLOCKER=""
  NOTE=""
  write_state
  append_history "start workflow=${WORKFLOW} phase=${PHASE} target=${TARGET:-none} label=${LABEL}"
  cmd_status
  echo
  cmd_next
}

cmd_status() {
  load_state
  print_header
  echo "created_at=${CREATED_AT}"
  echo "updated_at=${UPDATED_AT}"
  if [[ -n "${BLOCKER:-}" ]]; then
    echo "blocker=${BLOCKER}"
  fi
  if [[ -n "${NOTE:-}" ]]; then
    echo "note=${NOTE}"
  fi
}

cmd_next() {
  load_state
  case "${WORKFLOW}" in
    worktree-review) next_worktree_review ;;
    task-loop) next_task_loop ;;
    task-runner) next_task_runner ;;
    feature-dev) next_feature_dev ;;
    *) echo "sr-run: unknown workflow in state: ${WORKFLOW}" >&2; exit 1 ;;
  esac
}

cmd_advance() {
  if [[ $# -lt 1 ]]; then
    echo "sr-run: advance requires <phase>" >&2
    exit 1
  fi
  local next_phase="$1"
  shift
  parse_note_args "$@"

  load_state
  if ! phase_allowed "${WORKFLOW}" "${next_phase}"; then
    echo "sr-run: phase ${next_phase} is not valid for workflow ${WORKFLOW}" >&2
    exit 1
  fi
  check_phase_evidence "${WORKFLOW}" "${next_phase}"

  local old_phase="${PHASE}"
  PHASE="${next_phase}"
  UPDATED_AT="$(now_utc)"
  BLOCKER=""
  NOTE="${NOTE_ARG}"
  write_state
  append_history "advance workflow=${WORKFLOW} ${old_phase}->${PHASE} note=${NOTE}"
  cmd_status
  echo
  cmd_next
}

cmd_block() {
  if [[ $# -lt 1 ]]; then
    echo "sr-run: block requires a reason" >&2
    exit 1
  fi
  load_state
  local reason="$*"
  PHASE="blocked"
  UPDATED_AT="$(now_utc)"
  BLOCKER="${reason}"
  NOTE=""
  write_state
  append_history "block workflow=${WORKFLOW} reason=${BLOCKER}"
  cmd_status
}

cmd_done() {
  parse_note_args "$@"
  load_state
  PHASE="done"
  UPDATED_AT="$(now_utc)"
  BLOCKER=""
  NOTE="${NOTE_ARG}"
  write_state
  append_history "done workflow=${WORKFLOW} note=${NOTE}"
  cmd_status
}

cmd_clear() {
  rm -f "${STATE_FILE}" "${HISTORY_FILE}"
  echo "sr-run: cleared ${DRIVER_DIR}"
}

cmd="${1:-help}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "${cmd}" in
  start) acquire_lock; cmd_start "$@" ;;
  status) acquire_lock; cmd_status "$@" ;;
  next) acquire_lock; cmd_next "$@" ;;
  advance) acquire_lock; cmd_advance "$@" ;;
  block) acquire_lock; cmd_block "$@" ;;
  done) acquire_lock; cmd_done "$@" ;;
  clear) acquire_lock; cmd_clear "$@" ;;
  help|-h|--help) usage ;;
  *) echo "sr-run: unknown command: ${cmd}" >&2; usage >&2; exit 1 ;;
esac
