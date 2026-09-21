# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
FEATURE_NAME=tablet-mode
FEATURE_DESC="Auto-rotate screen, touchscreen and stylus on 2-in-1 laptops"
FEATURE_REQUIRES=omarchy
FEATURE_DEPENDS=(hyprland)

# Owns hypr/autostart.lua. If another feature needs autostart entries, move
# this file to a shared feature (one owner per file, see docs/features.md).

feature_verify() {
  command -v iio-hyprland >/dev/null
}
