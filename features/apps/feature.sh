# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
FEATURE_NAME=apps
FEATURE_DESC="Desktop apps: Chrome (default browser), Thunderbird, qBittorrent, VLC, Steam"
FEATURE_REQUIRES=any

feature_post_install() {
  command -v xdg-settings >/dev/null || return 0
  if [[ $(xdg-settings get default-web-browser 2>/dev/null) != google-chrome.desktop ]] \
    && [[ -f /usr/share/applications/google-chrome.desktop ]]; then
    changed
    run xdg-settings set default-web-browser google-chrome.desktop
  fi
}
