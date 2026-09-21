# shellcheck shell=bash
# Secrets never live in this repo. Features that need one call `secret_get NAME`,
# which looks in, in order:
#   1. the environment            (NAME=... ./install.sh)
#   2. pass                       (pass show omarchy-setup/NAME)
#   3. a local env file           (~/.config/omarchy-setup/secrets.env, chmod 600)
#   4. a GPG-encrypted env file   (~/.config/omarchy-setup/secrets.env.gpg)
# See secrets.example for the names in use and docs/secrets.md for setup.

SECRETS_FILE=${DOTCTL_SECRETS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-setup/secrets.env}

_secret_from_env_stream() { sed -n "s/^$1=//p" | tail -n1 | sed -e 's/^"//' -e 's/"$//'; }

secret_get() {
  local key=$1 value=${!1:-}
  [[ $key =~ ^[A-Z_][A-Z0-9_]*$ ]] || die "invalid secret name: $key"

  if [[ -z $value ]] && command -v pass >/dev/null && pass show "omarchy-setup/$key" >/dev/null 2>&1; then
    value=$(pass show "omarchy-setup/$key" | head -n1)
  fi
  if [[ -z $value && -f $SECRETS_FILE ]]; then
    [[ $(stat -c %a "$SECRETS_FILE") == 600 ]] || warn "$SECRETS_FILE should be chmod 600"
    value=$(_secret_from_env_stream "$key" <"$SECRETS_FILE")
  fi
  if [[ -z $value && -f $SECRETS_FILE.gpg ]]; then
    value=$(gpg --quiet --batch --decrypt "$SECRETS_FILE.gpg" 2>/dev/null | _secret_from_env_stream "$key")
  fi

  [[ -n $value ]] || return 1
  printf '%s' "$value"
}

# secret_require NAME... — fails early, before anything is changed, if a secret is missing.
secret_require() {
  local key missing=()
  for key in "$@"; do secret_get "$key" >/dev/null || missing+=("$key"); done
  ((${#missing[@]} == 0)) || die "missing secrets: ${missing[*]} (see secrets.example)"
}
