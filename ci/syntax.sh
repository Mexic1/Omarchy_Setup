#!/usr/bin/env bash
# Syntax checks for every config the repo links: bash, JSON, TOML, Lua, plus repo invariants.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
err() {
  echo "  ✗ $*" >&2
  status=1
}

echo "bash -n"
while IFS= read -r f; do bash -n "$f" || err "$f"; done < <(git ls-files -co --exclude-standard | grep -E '(\.sh$|^bin/|feature\.sh$|profile\.conf$)')

echo "json"
while IFS= read -r f; do jq empty "$f" 2>/dev/null || err "$f"; done < <(git ls-files -co --exclude-standard '*.json')

echo "toml"
while IFS= read -r f; do
  python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$f" || err "$f"
done < <(git ls-files -co --exclude-standard '*.toml')

echo "lua"
while IFS= read -r f; do luac -p "$f" || err "$f"; done < <(git ls-files -co --exclude-standard '*.lua')

echo "feature modules"
for dir in features/*/; do
  name=$(basename "$dir")
  [[ -f $dir/feature.sh ]] || {
    err "$dir has no feature.sh"
    continue
  }
  [[ $name == _* ]] && continue
  grep -qx "FEATURE_NAME=$name" "$dir/feature.sh" || err "$dir: FEATURE_NAME must be $name"
  for f in "$dir"packages/*.txt; do
    [[ -e $f ]] || continue
    case $(basename "$f") in pacman.txt | aur.txt | apt.txt | dnf.txt | zypper.txt | nix.txt) ;; *) err "$f: unknown package manager" ;; esac
  done
done

echo "no personal data"
# Email addresses or a git [user] block in anything that gets linked into $HOME.
if git ls-files -co --exclude-standard -z features profiles \
  | xargs -0 grep -nIE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|^\[user\]' 2>/dev/null \
  | grep -vE 'noreply@|@example\.|git@github\.com'; then
  err "lines above look like personal identity"
fi
# Private keys anywhere.
if git ls-files -co --exclude-standard -z | xargs -0 grep -lI 'BEGIN [A-Z ]*PRIVATE KEY' 2>/dev/null \
  | grep -v '^ci/syntax.sh$'; then
  err "files above contain a private key"
fi

exit $status
