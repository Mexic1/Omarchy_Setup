#!/usr/bin/env bash
# End-to-end test in a throwaway Arch container: real install of the ci profile,
# health check, idempotency, drift detection and rollback.
set -euo pipefail
cd "$(dirname "$0")/.."
export DOTCTL_ALLOW_ROOT=1 NO_COLOR=1
HOME=$(mktemp -d)
export HOME
step() { echo "::group::$*"; }
end() { echo "::endgroup::"; }

step "pre-existing config (must be backed up, then restored by rollback)"
mkdir -p "$HOME/.config/kitty"
echo "# pre-existing" >"$HOME/.config/kitty/kitty.conf"
end

step "install"
bin/dotctl install --profile ci --yes
end

step "verify"
bin/dotctl verify
end

step "idempotency: second run must change nothing"
bin/dotctl install --check
end

step "drift is detected"
rm "$HOME/.config/kitty/kitty.conf"
echo drift >"$HOME/.config/kitty/kitty.conf"
if bin/dotctl install --check >/dev/null; then
  echo "drift not detected" >&2
  exit 1
fi
bin/dotctl install --yes --no-packages >/dev/null
end

step "rollback restores the original"
bin/dotctl rollback --yes # undo the drift repair
bin/dotctl rollback --yes # undo the first install
grep -qx '# pre-existing' "$HOME/.config/kitty/kitty.conf"
[[ ! -e $HOME/.config/xdg-terminals.list ]]
end

echo "smoke test passed"
