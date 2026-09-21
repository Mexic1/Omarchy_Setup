# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
# Feature module template. Create a new one with: bin/dotctl new <name>
#
# A feature is one app or concern. Everything it needs lives in its folder:
#   feature.sh           this file: metadata and optional hooks
#   home/                files linked into $HOME at the same path
#                        (home/.config/foo/foo.conf -> ~/.config/foo/foo.conf)
#   packages/<pm>.txt    one package per line for pacman, apt, dnf, zypper, nix;
#                        aur.txt is used on Arch only. Omit a file = nothing to install.

# Must match the folder name.
FEATURE_NAME=template

# One line, shown by `dotctl list`.
FEATURE_DESC="What this feature sets up"

# "omarchy" = skipped on machines without Omarchy; "any" = portable.
FEATURE_REQUIRES=any

# Features that must be applied first (their packages/links/hooks run earlier).
FEATURE_DEPENDS=()

# systemd units enabled (and started) after the post-install hook.
FEATURE_SERVICES_USER=()
FEATURE_SERVICES_SYSTEM=()

# Hooks are optional and MUST be idempotent: check first, then act.
# Wrap every command that changes the system in `run` (it honours --dry-run)
# and call `changed` when you act, so `install --check` can detect drift.
# Available helpers: run, changed, info, warn, die, pkg_is_installed, secret_get.

# Runs after packages are installed, before configs are linked.
# feature_pre_install() {
#   :
# }

# Runs after configs are linked, before services are enabled.
# feature_post_install() {
#   if ! some-check; then
#     changed
#     run some-command
#   fi
# }

# Extra health check for `dotctl verify`. Return non-zero on failure.
# feature_verify() {
#   command -v foo >/dev/null
# }
