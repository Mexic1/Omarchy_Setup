# shellcheck shell=bash
# Distro detection, validation and Omarchy bootstrap.

OMARCHY_INSTALL_URL=https://omarchy.org/install

os_detect() {
  OS_ID=$(. /etc/os-release 2>/dev/null && echo "${ID:-unknown}")
  OS_LIKE=$(. /etc/os-release 2>/dev/null && echo "${ID_LIKE:-}")

  IS_OMARCHY=0
  if [[ -d /usr/share/omarchy ]] || command -v omarchy >/dev/null 2>&1; then
    IS_OMARCHY=1
  fi

  # PKG_MANAGER can be forced (e.g. PKG_MANAGER=nix on a non-NixOS host).
  if [[ -z ${PKG_MANAGER:-} ]]; then
    if [[ $OS_ID == nixos ]]; then
      PKG_MANAGER=nix
    elif command -v pacman >/dev/null; then
      PKG_MANAGER=pacman
    elif command -v apt-get >/dev/null; then
      PKG_MANAGER=apt
    elif command -v dnf >/dev/null; then
      PKG_MANAGER=dnf
    elif command -v zypper >/dev/null; then
      PKG_MANAGER=zypper
    elif command -v nix >/dev/null; then
      PKG_MANAGER=nix
    else
      PKG_MANAGER=none
    fi
  fi

  AUR_HELPER=''
  if [[ $PKG_MANAGER == pacman ]]; then
    for h in yay paru; do command -v "$h" >/dev/null && AUR_HELPER=$h && break; done
  fi

  SUDO=''
  if ((EUID != 0)); then SUDO=sudo; fi
}

os_validate() {
  log "Checking system"
  ((BASH_VERSINFO[0] >= 5)) || die "bash 5+ required (found $BASH_VERSION)"
  command -v git >/dev/null || die "git is required"
  if ((EUID == 0)) && [[ -z ${DOTCTL_ALLOW_ROOT:-} ]]; then
    die "run as your normal user, not root (sudo is used only where needed)"
  fi
  [[ $PKG_MANAGER != none ]] || die "no supported package manager (pacman, apt, dnf, zypper, nix)"

  info "distro: $OS_ID${OS_LIKE:+ (like $OS_LIKE)} · packages: $PKG_MANAGER${AUR_HELPER:+ + $AUR_HELPER}"
  if ((IS_OMARCHY)); then
    ok "Omarchy $(omarchy version 2>/dev/null || cat /usr/share/omarchy/version 2>/dev/null || echo '?')"
  else
    warn "Omarchy not detected: features marked FEATURE_REQUIRES=omarchy will be skipped"
  fi
}

# Installs Omarchy on a plain Arch system. Only with --bootstrap-omarchy,
# because it runs the official remote installer and reboots into a new desktop.
os_bootstrap_omarchy() {
  ((IS_OMARCHY)) && return 0
  ((BOOTSTRAP_OMARCHY)) || return 0
  [[ $OS_ID == arch ]] || die "Omarchy can only be bootstrapped on Arch Linux (found $OS_ID)"

  log "Bootstrapping Omarchy"
  info "This runs the official installer from $OMARCHY_INSTALL_URL"
  confirm "Install Omarchy now?" || die "aborted"
  local script
  script=$(curl -fsSL "$OMARCHY_INSTALL_URL") || die "could not download the Omarchy installer"
  run bash -c "$script"
  ((DRY_RUN)) && return 0
  log "Omarchy installed. Reboot, log in, then run ./install.sh again."
  exit 0
}
