# shellcheck shell=bash
# Output helpers, the dry-run wrapper and the change counter used for idempotency checks.

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  C_B=$'\e[1m' C_R=$'\e[31m' C_G=$'\e[32m' C_Y=$'\e[33m' C_D=$'\e[2m' C_0=$'\e[0m'
else
  C_B='' C_R='' C_G='' C_Y='' C_D='' C_0=''
fi

DRY_RUN=${DRY_RUN:-0}
VERBOSE=${VERBOSE:-0}
CHANGES=0

log() { printf '%s==>%s %s%s%s\n' "$C_B" "$C_0" "$C_B" "$*" "$C_0"; }
info() { printf '    %s\n' "$*"; }
ok() { printf '    %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '    %s!%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
fail() { printf '    %s✗%s %s\n' "$C_R" "$C_0" "$*" >&2; }
debug() { ((VERBOSE)) && printf '    %s%s%s\n' "$C_D" "$*" "$C_0" || true; }
die() {
  printf '%serror:%s %s\n' "$C_R" "$C_0" "$*" >&2
  exit 1
}

# run CMD... — execute CMD, or only print it when DRY_RUN=1.
run() {
  if ((DRY_RUN)); then
    printf '    %s[dry-run]%s %s\n' "$C_D" "$C_0" "$*"
  else
    debug "+ $*"
    "$@"
  fi
}

# Call whenever something on the system is (or would be) modified.
# `install --check` fails if a second run still counts changes.
changed() { CHANGES=$((CHANGES + 1)); }

confirm() {
  ((ASSUME_YES)) && return 0
  local reply
  read -r -p "    $* [y/N] " reply </dev/tty
  [[ $reply == [yY]* ]]
}
