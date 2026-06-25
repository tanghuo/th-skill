#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT_DIR}" ]]; then
  echo "srctl: must run inside a git repository" >&2
  exit 1
fi
cd "${ROOT_DIR}"

GATE_DIR=".local/sr-gate"
FREEZE_PATCH="${GATE_DIR}/freeze.patch"
FROZEN_FILES="${GATE_DIR}/frozen-files"
FREEZE_META="${GATE_DIR}/freeze-meta"
CHECK_PASS="${GATE_DIR}/check-pass"
CHECK_LOG="${GATE_DIR}/check.log"
LOCK_DIR="${GATE_DIR}/.lock"
HOOK_FILE=".git/hooks/pre-commit"

usage() {
  cat <<'EOF'
Usage:
  .local/srctl.sh install-hook
  .local/srctl.sh freeze [--refresh --reason <text>] [label...]
  .local/srctl.sh check -- command...
  .local/srctl.sh verify
  .local/srctl.sh status
  .local/srctl.sh clear

V0 commit hygiene gate:
  freeze       Record the current allowed worktree target.
  check        Run a heavier validation command and bind success to the current staged diff hash.
  verify       Cheap pre-commit verification: freeze exists, staged files are within freeze,
               git diff --cached --check passes, and check-pass matches current staged hash.
  install-hook Install a git pre-commit hook that calls .local/srctl.sh verify.
EOF
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

release_lock() {
  if [[ "${SRCTL_LOCKED:-0}" == "1" ]]; then
    rmdir "${LOCK_DIR}" 2>/dev/null || true
  fi
}

acquire_lock() {
  mkdir -p "${GATE_DIR}"
  local i
  for i in {1..100}; do
    if mkdir "${LOCK_DIR}" 2>/dev/null; then
      SRCTL_LOCKED=1
      trap release_lock EXIT
      return 0
    fi
    sleep 0.1
  done

  echo "srctl: another srctl command is still running; lock=${LOCK_DIR}" >&2
  exit 1
}

staged_diff_hash() {
  git diff --cached --binary -- . | git hash-object --stdin
}

has_staged_diff() {
  ! git diff --cached --quiet -- .
}

current_head() {
  git rev-parse HEAD
}

write_dirty_file_set() {
  {
    git diff --name-only -- .
    git diff --cached --name-only -- .
    git ls-files --others --exclude-standard
  } | LC_ALL=C sort -u
}

require_freeze() {
  if [[ ! -f "${FREEZE_META}" || ! -f "${FROZEN_FILES}" ]]; then
    echo "srctl: no freeze found; run .local/srctl.sh freeze before committing" >&2
    exit 1
  fi
}

load_meta_value() {
  local key="$1"
  awk -F= -v key="${key}" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "${FREEZE_META}" 2>/dev/null || true
}

write_freeze_meta() {
  local label="$1"
  local mode="$2"
  local reason="$3"
  {
    printf 'created_at=%s\n' "$(now_utc)"
    printf 'head=%s\n' "$(current_head)"
    printf 'label=%s\n' "${label}"
    printf 'mode=%s\n' "${mode}"
    printf 'reason=%s\n' "${reason}"
  } > "${FREEZE_META}"
}

cmd_install_hook() {
  mkdir -p "$(dirname "${HOOK_FILE}")"

  if [[ -f "${HOOK_FILE}" ]] && ! grep -q 'srctl commit hygiene gate' "${HOOK_FILE}"; then
    local backup="${HOOK_FILE}.srctl-backup-$(date -u +%Y%m%dT%H%M%SZ)"
    cp "${HOOK_FILE}" "${backup}"
    echo "srctl: existing pre-commit hook backed up to ${backup}"
  fi

  cat > "${HOOK_FILE}" <<'EOF'
#!/usr/bin/env bash
# srctl commit hygiene gate
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

exec .local/srctl.sh verify
EOF
  chmod +x "${HOOK_FILE}"
  echo "srctl: installed ${HOOK_FILE}"
}

cmd_freeze() {
  local refresh=0
  local reason=""
  local label_parts=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --refresh)
        refresh=1
        shift
        ;;
      --reason)
        if [[ $# -lt 2 ]]; then
          echo "srctl: --reason requires text" >&2
          exit 1
        fi
        reason="$2"
        shift 2
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          label_parts+=("$1")
          shift
        done
        ;;
      *)
        label_parts+=("$1")
        shift
        ;;
    esac
  done

  if [[ -f "${FREEZE_META}" && "${refresh}" != "1" ]]; then
    echo "srctl: freeze already exists; use --refresh --reason <text> to replace it visibly" >&2
    exit 1
  fi
  if [[ "${refresh}" == "1" && -z "${reason}" ]]; then
    echo "srctl: --refresh requires --reason <text>" >&2
    exit 1
  fi

  mkdir -p "${GATE_DIR}"

  local label="${label_parts[*]:-worktree}"
  write_dirty_file_set > "${FROZEN_FILES}"
  git diff --binary -- . > "${FREEZE_PATCH}"
  git diff --cached --binary -- . >> "${FREEZE_PATCH}"
  write_freeze_meta "${label}" "$([[ "${refresh}" == "1" ]] && echo refresh || echo freeze)" "${reason}"
  rm -f "${CHECK_PASS}" "${CHECK_LOG}"

  echo "srctl: frozen target into ${GATE_DIR}"
  echo "srctl: frozen files: $(wc -l < "${FROZEN_FILES}" | tr -d ' ')"
}

cmd_check() {
  if [[ $# -gt 0 && "$1" == "--" ]]; then
    shift
  fi
  if [[ $# -eq 0 ]]; then
    echo "srctl: check requires a validation command" >&2
    exit 1
  fi
  require_freeze
  if ! has_staged_diff; then
    echo "srctl: check blocked: staged diff is empty; stage the coherent change set first" >&2
    exit 1
  fi

  local hash_before
  hash_before="$(staged_diff_hash)"

  echo "srctl: running check for staged hash ${hash_before}: $*"
  set +e
  "$@" 2>&1 | tee "${CHECK_LOG}"
  local check_exit="${PIPESTATUS[0]}"
  set -e

  if [[ "${check_exit}" != "0" ]]; then
    rm -f "${CHECK_PASS}"
    echo "srctl: check failed with exit ${check_exit}" >&2
    exit "${check_exit}"
  fi

  local hash_after
  hash_after="$(staged_diff_hash)"
  if [[ "${hash_after}" != "${hash_before}" ]]; then
    rm -f "${CHECK_PASS}"
    echo "srctl: check blocked: staged diff changed while validation was running" >&2
    exit 1
  fi

  {
    printf 'checked_at=%s\n' "$(now_utc)"
    printf 'head=%s\n' "$(current_head)"
    printf 'staged_hash=%s\n' "${hash_after}"
    printf 'command=%q' "$1"
    shift
    local arg
    for arg in "$@"; do
      printf ' %q' "${arg}"
    done
    printf '\n'
  } > "${CHECK_PASS}"

  echo "srctl: check passed and bound to staged hash ${hash_after}"
}

cmd_verify() {
  require_freeze

  if ! has_staged_diff; then
    echo "srctl: commit blocked: staged diff is empty" >&2
    exit 1
  fi

  local freeze_head
  freeze_head="$(load_meta_value head)"
  if [[ -n "${freeze_head}" && "${freeze_head}" != "$(current_head)" ]]; then
    echo "srctl: commit blocked: HEAD changed since freeze; refresh freeze with an explicit reason" >&2
    exit 1
  fi

  local staged_file missing=0
  while IFS= read -r staged_file; do
    [[ -n "${staged_file}" ]] || continue
    if ! grep -Fxq -- "${staged_file}" "${FROZEN_FILES}"; then
      echo "srctl: commit blocked: staged file was not in frozen target: ${staged_file}" >&2
      missing=1
    fi
  done < <(git diff --cached --name-only -- .)
  if [[ "${missing}" != "0" ]]; then
    echo "srctl: refresh freeze only when the target legitimately changed" >&2
    exit 1
  fi

  git diff --cached --check -- .

  if [[ ! -f "${CHECK_PASS}" ]]; then
    echo "srctl: commit blocked: no passing check is bound to the current staged diff" >&2
    echo "srctl: run .local/srctl.sh check -- <validation command>" >&2
    exit 1
  fi

  local expected_hash current_hash
  expected_hash="$(awk -F= '$1 == "staged_hash" { sub(/^[^=]*=/, ""); print; exit }' "${CHECK_PASS}")"
  current_hash="$(staged_diff_hash)"
  if [[ "${expected_hash}" != "${current_hash}" ]]; then
    echo "srctl: commit blocked: staged diff changed after the last passing check" >&2
    echo "srctl: checked hash=${expected_hash}" >&2
    echo "srctl: current hash=${current_hash}" >&2
    exit 1
  fi

  echo "srctl: commit hygiene gate passed"
}

cmd_status() {
  if [[ ! -f "${FREEZE_META}" ]]; then
    echo "freeze: missing"
  else
    echo "freeze: present"
    sed -n '1,20p' "${FREEZE_META}"
    echo "frozen_files=$(wc -l < "${FROZEN_FILES}" | tr -d ' ')"
  fi

  if has_staged_diff; then
    echo "staged_hash=$(staged_diff_hash)"
  else
    echo "staged_hash=<empty>"
  fi

  if [[ -f "${CHECK_PASS}" ]]; then
    echo "check: present"
    sed -n '1,20p' "${CHECK_PASS}"
  else
    echo "check: missing"
  fi

  if [[ -f "${HOOK_FILE}" ]] && grep -q 'srctl commit hygiene gate' "${HOOK_FILE}"; then
    echo "hook: installed"
  else
    echo "hook: missing"
  fi
}

cmd_clear() {
  rm -f "${FREEZE_PATCH}" "${FROZEN_FILES}" "${FREEZE_META}" "${CHECK_PASS}" "${CHECK_LOG}"
  echo "srctl: cleared ${GATE_DIR}"
}

cmd="${1:-help}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "${cmd}" in
  install-hook) acquire_lock; cmd_install_hook "$@" ;;
  freeze) acquire_lock; cmd_freeze "$@" ;;
  check) acquire_lock; cmd_check "$@" ;;
  verify) acquire_lock; cmd_verify "$@" ;;
  status) acquire_lock; cmd_status "$@" ;;
  clear) acquire_lock; cmd_clear "$@" ;;
  help|-h|--help) usage ;;
  *)
    echo "srctl: unknown command: ${cmd}" >&2
    usage >&2
    exit 1
    ;;
esac
