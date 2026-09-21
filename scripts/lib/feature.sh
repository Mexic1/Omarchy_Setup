# shellcheck shell=bash
# shellcheck disable=SC2086 # $SUDO is intentionally unquoted (empty when root)
# Feature modules and profiles. See docs/features.md for the module contract.

FEATURES_DIR=$REPO_DIR/features
PROFILES_DIR=$REPO_DIR/profiles

# Loads features/<name>/feature.sh into the current shell, resetting the
# metadata and hooks left over from the previously loaded feature.
feature_load() {
  local name=$1
  FEATURE_DIR=$FEATURES_DIR/$name
  [[ $name != _* && -f $FEATURE_DIR/feature.sh ]] || die "unknown feature: $name"
  FEATURE_NAME=$name FEATURE_DESC='' FEATURE_REQUIRES=any
  FEATURE_DEPENDS=() FEATURE_SERVICES_USER=() FEATURE_SERVICES_SYSTEM=()
  unset -f feature_pre_install feature_post_install feature_verify
  # shellcheck source=/dev/null
  source "$FEATURE_DIR/feature.sh"
  [[ $FEATURE_NAME == "$name" ]] || die "features/$name/feature.sh declares FEATURE_NAME=$FEATURE_NAME"
}

feature_supported() {
  [[ $FEATURE_REQUIRES != omarchy ]] || ((IS_OMARCHY))
}

feature_call() {
  declare -F "$1" >/dev/null || return 0
  debug "$FEATURE_NAME: $1"
  "$1"
}

# profile_features NAME — prints the profile's feature list, following PROFILE_EXTENDS.
profile_features() {
  local conf=$PROFILES_DIR/$1/profile.conf
  [[ -f $conf ]] || die "unknown profile: $1 (see bin/dotctl list)"
  (
    PROFILE_EXTENDS='' FEATURES=()
    # shellcheck source=/dev/null
    source "$conf"
    [[ -n $PROFILE_EXTENDS ]] && profile_features "$PROFILE_EXTENDS"
    printf '%s\n' "${FEATURES[@]}"
  )
}

# profile_chain NAME — the profile and its ancestors, base first (for overlays).
profile_chain() {
  local parent
  # shellcheck source=/dev/null
  parent=$(PROFILE_EXTENDS='' && source "$PROFILES_DIR/$1/profile.conf" && echo "$PROFILE_EXTENDS")
  [[ -n $parent ]] && profile_chain "$parent"
  echo "$1"
}

# resolve_features NAME... — dependency-ordered, de-duplicated list in ORDER.
declare -ga ORDER=()
declare -gA _SEEN=()
resolve_features() {
  local f deps
  for f in "$@"; do
    [[ ${_SEEN[$f]:-} == "done" ]] && continue
    [[ ${_SEEN[$f]:-} == visiting ]] && die "dependency cycle at feature $f"
    _SEEN[$f]=visiting
    deps=$(feature_load "$f" && echo "${FEATURE_DEPENDS[*]}")
    # shellcheck disable=SC2086 # word-split the dependency list
    [[ -n $deps ]] && resolve_features $deps
    _SEEN[$f]="done"
    ORDER+=("$f")
  done
}

svc_enable() {
  local scope=$1 unit=$2
  local -a ctl=(systemctl --user)
  [[ $scope == system ]] && ctl=(${SUDO:+"$SUDO"} systemctl)
  svc_is_enabled "$scope" "$unit" && return 0
  changed
  info "enable $scope service $unit"
  run "${ctl[@]}" enable --now "$unit"
  txn_record SERVICE "$scope" "$unit"
}

svc_is_enabled() {
  if [[ $1 == user ]]; then
    systemctl --user is-enabled --quiet "$2" 2>/dev/null
  else
    systemctl is-enabled --quiet "$2" 2>/dev/null
  fi
}
