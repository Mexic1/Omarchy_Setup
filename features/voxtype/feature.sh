# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
FEATURE_NAME=voxtype
FEATURE_DESC="Voice dictation (hold F9) with a local Whisper model"
FEATURE_REQUIRES=omarchy
FEATURE_SERVICES_USER=(voxtype.service)

# Uses Omarchy's default voxtype config, so nothing is linked. Mirrors
# omarchy-voxtype-install without its interactive prompt.
feature_post_install() {
  if [[ ! -f $HOME/.config/voxtype/config.toml ]]; then
    changed
    run mkdir -p "$HOME/.config/voxtype"
    run cp "${OMARCHY_PATH:-/usr/share/omarchy}/default/voxtype/config.toml" "$HOME/.config/voxtype/"
  fi
  if ! compgen -G "$HOME/.local/share/voxtype/models/*" >/dev/null; then
    changed
    run voxtype setup --download --no-post-install
    run bash -c 'omarchy-hw-vulkan && voxtype setup gpu --enable || true'
  fi
  if [[ ! -f $HOME/.config/systemd/user/voxtype.service ]]; then
    changed
    run voxtype setup systemd
  fi
}
