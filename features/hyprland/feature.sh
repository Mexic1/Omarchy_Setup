# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
FEATURE_NAME=hyprland
FEATURE_DESC="Touchpad (natural scroll, gestures), click-to-focus, no focus jump between monitors"
FEATURE_REQUIRES=omarchy

feature_verify() {
  command -v hyprctl >/dev/null || return 0 # not inside a Hyprland session (e.g. CI)
  ! hyprctl configerrors 2>/dev/null | grep -q .
}
