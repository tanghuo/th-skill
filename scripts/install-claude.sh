#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${HOME}/.claude/skills"

mkdir -p "${target}"
rsync -a "${repo_root}/skills/" "${target}/"

echo "Installed skills to ${target}"

