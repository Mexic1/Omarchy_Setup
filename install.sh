#!/usr/bin/env bash
# Restore this setup on a machine: install Omarchy, clone this repo, run ./install.sh.
# Safe to re-run: it only changes what differs from the repo.
#
#   ./install.sh                            # default profile (or the one used last time)
#   ./install.sh -p laptop-convertible      # pick a profile
#   ./install.sh --dry-run                  # show what would change
#   ./install.sh --only kitty,mise          # just some features
#
# All options: ./install.sh --help. Everything else: bin/dotctl help.
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  exec bin/dotctl help
fi

exec bin/dotctl install "$@"
