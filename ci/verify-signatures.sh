#!/usr/bin/env bash
# Verifies that a release tag (and the commit it points to) is signed by a
# maintainer key listed in .github/allowed_signers (SSH signing format:
# "<principal> <key-type> <public-key>", no email needed).
set -euo pipefail
cd "$(dirname "$0")/.."
tag=${1:?usage: ci/verify-signatures.sh <tag>}
signers=.github/allowed_signers

[[ -s $signers ]] || {
  echo "::error::$signers is missing; see docs/git-flow.md#signing" >&2
  exit 1
}

git config gpg.format ssh
git config gpg.ssh.allowedSignersFile "$signers"
git verify-tag "$tag"
git verify-commit "$tag^{commit}"
echo "signature OK for $tag"
