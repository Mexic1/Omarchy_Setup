# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
FEATURE_NAME=omarchy-shell
FEATURE_DESC="Transparent bar, longer idle/lock timers, Better Displays Pro widget"
FEATURE_REQUIRES=omarchy

# Third-party plugin, pinned to a commit so a new machine gets exactly the
# reviewed code. To update: check the changes upstream, then bump PLUGIN_REF.
PLUGIN_ID=io.github.dragosol.better-displays-pro
PLUGIN_URL=https://github.com/dragosol/omarchy-better-displays.git
PLUGIN_REF=0c327f10ac9759852af0fcd6f42b54f3a8c372e0

feature_post_install() {
  local dir=$HOME/.config/omarchy/plugins/$PLUGIN_ID
  if [[ ! -d $dir/.git ]]; then
    changed
    run git clone --quiet "$PLUGIN_URL" "$dir"
  fi
  if [[ $(git -C "$dir" rev-parse HEAD 2>/dev/null) != "$PLUGIN_REF" ]]; then
    changed
    run git -C "$dir" fetch --quiet origin
    run git -C "$dir" -c advice.detachedHead=false checkout --quiet "$PLUGIN_REF"
  fi
}

feature_verify() {
  local dir=$HOME/.config/omarchy/plugins/$PLUGIN_ID
  [[ $(git -C "$dir" rev-parse HEAD 2>/dev/null) == "$PLUGIN_REF" ]]
}
