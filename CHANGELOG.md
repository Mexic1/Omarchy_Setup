# Changelog

All notable changes to this setup. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versions: [SemVer](https://semver.org) as defined in [docs/git-flow.md](docs/git-flow.md#versioning-semver-for-a-dotfiles-repo).

## [Unreleased]

## [0.1.0] - 2026-09-21

### Added
- `install.sh` and `bin/dotctl`: install, plan, verify, status, adopt, rollback, history, new, list, doctor.
- Package layer for pacman/AUR, apt, dnf, zypper and nix.
- Transactions with backups, automatic rollback on failure, and `dotctl rollback`.
- Features: hyprland, omarchy-shell, kitty, herdr, mise, apps, tablet-mode, voxtype.
- Profiles: default, laptop-convertible, ci.
- CI: shellcheck, shfmt, syntax checks, gitleaks, dry run on Arch/Ubuntu/Fedora/openSUSE/Nix, smoke test.
- Signed-tag release workflow with checksums.
