#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_repo="${1:-$(pwd)}"

usage() {
  cat <<'EOF'
Usage:
  scripts/install-sr-gate.sh [target-repo]

Install the repo-local srctl commit hygiene gate into target-repo:
  - copies templates/sr-gate/srctl.sh to <target-repo>/.local/srctl.sh
  - installs <target-repo>/.git/hooks/pre-commit via .local/srctl.sh install-hook

Existing .local/srctl.sh is backed up before replacement.
EOF
}

case "${target_repo}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [[ ! -d "${target_repo}/.git" ]]; then
  echo "install-sr-gate: target is not a git repository: ${target_repo}" >&2
  exit 1
fi

target_repo="$(cd "${target_repo}" && pwd)"
src="${repo_root}/templates/sr-gate/srctl.sh"
dest="${target_repo}/.local/srctl.sh"

if [[ ! -f "${src}" ]]; then
  echo "install-sr-gate: missing template: ${src}" >&2
  exit 1
fi

mkdir -p "${target_repo}/.local"

if [[ -f "${dest}" ]] && ! cmp -s "${src}" "${dest}"; then
  backup="${dest}.backup-$(date -u +%Y%m%dT%H%M%SZ)"
  cp -p "${dest}" "${backup}"
  echo "install-sr-gate: backed up existing srctl to ${backup}"
fi

cp -p "${src}" "${dest}"
chmod +x "${dest}"

(
  cd "${target_repo}"
  .local/srctl.sh install-hook
)

echo "install-sr-gate: installed sr gate into ${target_repo}"
