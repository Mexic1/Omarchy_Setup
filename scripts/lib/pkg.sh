# shellcheck shell=bash
# shellcheck disable=SC2086 # $SUDO is intentionally unquoted (empty when root)
# Package abstraction. Each feature lists packages per manager in
# features/<name>/packages/<manager>.txt (aur.txt is used only with pacman).

# Prints the package names in a manifest, without comments or blank lines.
pkg_read_manifest() {
  [[ -f $1 ]] || return 0
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$1"
}

pkg_is_installed() {
  case $PKG_MANAGER in
    pacman) pacman -Q "$1" >/dev/null 2>&1 ;;
    apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed' ;;
    dnf | zypper) rpm -q --whatprovides "$1" >/dev/null 2>&1 ;;
    nix) nix profile list 2>/dev/null | grep -qE "\.$1\$" ;;
    *) return 1 ;;
  esac
}

_APT_UPDATED=0

# pkg_install SOURCE PKG... — SOURCE is "native" or "aur". Installs only what is missing.
pkg_install() {
  local source=$1
  shift
  local missing=() p
  for p in "$@"; do pkg_is_installed "$p" || missing+=("$p"); done
  ((${#missing[@]})) || return 0

  changed
  info "installing (${source/native/$PKG_MANAGER}): ${missing[*]}"
  if [[ $source == aur ]]; then
    if ((IS_OMARCHY)); then
      run omarchy-pkg-aur-add "${missing[@]}"
    elif [[ -n $AUR_HELPER ]]; then
      run "$AUR_HELPER" -S --needed --noconfirm "${missing[@]}"
    elif ((DRY_RUN)); then
      warn "no AUR helper (yay/paru): would fail to install ${missing[*]}"
    else
      die "AUR packages needed (${missing[*]}) but no AUR helper (yay/paru) found"
    fi
    return
  fi

  case $PKG_MANAGER in
    pacman)
      if ((IS_OMARCHY)); then
        run omarchy-pkg-add "${missing[@]}"
      else
        run $SUDO pacman -S --needed --noconfirm "${missing[@]}"
      fi
      ;;
    apt)
      if ((_APT_UPDATED == 0)); then run $SUDO apt-get update -qq && _APT_UPDATED=1; fi
      run $SUDO apt-get install -y "${missing[@]}"
      ;;
    dnf) run $SUDO dnf install -y "${missing[@]}" ;;
    zypper) run $SUDO zypper --non-interactive install "${missing[@]}" ;;
    nix) for p in "${missing[@]}"; do run nix profile install "nixpkgs#$p"; done ;;
  esac
}

# pkg_feature_packages DIR — installs the missing packages from a feature's manifests.
pkg_feature_packages() {
  local dir=$1
  local -a native aur
  mapfile -t native < <(pkg_read_manifest "$dir/packages/$PKG_MANAGER.txt")
  ((${#native[@]})) && pkg_install native "${native[@]}"
  if [[ $PKG_MANAGER == pacman ]]; then
    mapfile -t aur < <(pkg_read_manifest "$dir/packages/aur.txt")
    ((${#aur[@]})) && pkg_install aur "${aur[@]}"
  fi
  return 0
}

pkg_feature_missing() {
  local dir=$1 p
  local files=("$dir/packages/$PKG_MANAGER.txt")
  [[ $PKG_MANAGER == pacman ]] && files+=("$dir/packages/aur.txt")
  for f in "${files[@]}"; do
    while read -r p; do pkg_is_installed "$p" || echo "$p"; done < <(pkg_read_manifest "$f")
  done
}
