# shellcheck shell=bash
# shellcheck disable=SC2034 # variables are read by bin/dotctl
FEATURE_NAME=mise
FEATURE_DESC="mise with global tools: node, gh and AI CLIs"
FEATURE_REQUIRES=any

feature_post_install() {
  command -v mise >/dev/null || return 0 # dry run before mise is installed
  if [[ -n $(mise ls --global --missing 2>/dev/null) ]]; then
    changed
    run mise install --yes
  fi
}

feature_verify() {
  [[ -z $(mise ls --global --missing 2>/dev/null) ]]
}
