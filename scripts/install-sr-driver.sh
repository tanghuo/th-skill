#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_repo="${1:-$(pwd)}"

usage() {
  cat <<'EOF'
Usage:
  scripts/install-sr-driver.sh [target-repo]

Install the repo-local sr workflow state driver into target-repo:
  - copies templates/sr-driver/sr-run.sh to <target-repo>/.local/sr-run.sh

Existing .local/sr-run.sh is backed up before replacement.
EOF
}

case "${target_repo}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [[ ! -d "${target_repo}/.git" ]]; then
  echo "install-sr-driver: target is not a git repository: ${target_repo}" >&2
  exit 1
fi

target_repo="$(cd "${target_repo}" && pwd)"
src="${repo_root}/templates/sr-driver/sr-run.sh"
dest="${target_repo}/.local/sr-run.sh"

if [[ ! -f "${src}" ]]; then
  echo "install-sr-driver: missing template: ${src}" >&2
  exit 1
fi

mkdir -p "${target_repo}/.local"

if [[ -f "${dest}" ]] && ! cmp -s "${src}" "${dest}"; then
  backup="${dest}.backup-$(date -u +%Y%m%dT%H%M%SZ)"
  cp -p "${dest}" "${backup}"
  echo "install-sr-driver: backed up existing sr-run to ${backup}"
fi

cp -p "${src}" "${dest}"
chmod +x "${dest}"

echo "install-sr-driver: installed sr driver into ${target_repo}"
