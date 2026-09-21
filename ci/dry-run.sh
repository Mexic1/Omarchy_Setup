#!/usr/bin/env bash
# Runs a dry-run install in the current container. Used by the CI distro matrix.
# Checks that detection, profile resolution and package lookup work everywhere.
set -euo pipefail
cd "$(dirname "$0")/.."
export DOTCTL_ALLOW_ROOT=1 NO_COLOR=1

for profile in default laptop-convertible ci; do
  echo "::group::dry-run $profile"
  bin/dotctl plan --profile "$profile" --yes
  echo "::endgroup::"
done
