#!/usr/bin/env bash
# Shell lint: shellcheck + shfmt formatting on every bash file in the repo.
set -euo pipefail
cd "$(dirname "$0")/.."

mapfile -t files < <(git ls-files -co --exclude-standard \
  | grep -E '(\.sh$|^bin/|^install\.sh$|feature\.sh$|profile\.conf$)' | grep -v '^migrations/README')

echo "shellcheck: ${#files[@]} files"
shellcheck -x "${files[@]}"

echo "shfmt"
shfmt -d -i 2 -ci -bn "${files[@]}"
