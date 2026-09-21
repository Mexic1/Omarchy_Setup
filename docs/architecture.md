# Architecture

## Goals

| Goal | How |
|---|---|
| Rebuild a machine with one command | Omarchy + `git clone` + `./install.sh` |
| Store only what I changed | Features hold diffs from Omarchy's defaults, not copies of everything |
| Safe to re-run | Every step checks before acting; `install --check` proves a second run is a no-op |
| Nothing is lost | Replaced files are backed up per run; any failure rolls the run back |
| Easy to extend | A new app = a new folder under `features/`, no changes to the installer |
| No personal data | Secrets resolved at install time from env / pass / GPG; CI scans for leaks |

## Install flow

```
./install.sh [options]
  └─ bin/dotctl install
       1. Detect      distro, package manager (pacman/apt/dnf/zypper/nix), AUR helper, Omarchy
       2. Validate    bash 5, git, not root, supported package manager
       3. Bootstrap   only with --bootstrap-omarchy on plain Arch: official Omarchy installer, then exit
       4. Resolve     profile → features (+ --with, − --skip, or --only) → dependency order
                      features needing Omarchy are skipped on other systems
       5. Plan        collect links from features + profile overlays; conflicts stop here, before any change
       6. Confirm     (skipped with --yes; nothing below runs with --dry-run)
       7. Lock        flock on the state dir: one run at a time
       ── transaction starts: every change is journaled ──
       8. Packages    per feature, only missing ones
       9. Pre-hooks   feature_pre_install (e.g. secret_require)
      10. Links       atomic symlink swap, originals backed up; links no feature provides any more are removed
      11. Post-hooks  feature_post_install (plugins, model downloads, default apps)
      12. Services    systemd user/system units, enabled only if not already
      13. Migrations  one-off scripts not yet applied on this machine
       ── commit (or automatic rollback if any step failed) ──
      14. Verify      links, packages, services, feature_verify hooks
```

## Symlink plan

- Every file under `features/<name>/home/` is linked to the same path under `$HOME`:
  `features/kitty/home/.config/kitty/kitty.conf` → `~/.config/kitty/kitty.conf`.
- Files are linked one by one, never whole directories. Omarchy keeps writing its own files
  next to ours (e.g. `~/.config/hypr/bindings.lua` stays Omarchy's).
- **One owner per file.** Two features providing the same path is an error at plan time.
- **Profile overlays** (`profiles/<name>/home/`) may override any feature file. That's where
  machine-specific files go, such as `hypr/monitors.lua` for a given display layout. Overlays
  follow `PROFILE_EXTENDS`, base profile first.
- **Drift:** some programs save by writing a new file over the link (Omarchy migrations using
  `sed -i`, `omarchy refresh`, GUI settings). `dotctl status` reports these as *drifted*;
  `dotctl adopt` copies the new content into the repo and re-links, and `dotctl install` puts the
  repo version back (after backing up the drifted file).

Why not GNU stow: stow links directories when it can (Omarchy would then write into the repo),
has no backup/rollback, and is one more dependency. The linker is ~100 lines in `scripts/lib/link.sh`.

## Package layer

Each feature lists packages per manager; the installer picks the file for the detected manager.

```
features/apps/packages/
  pacman.txt    thunderbird qbittorrent vlc steam
  aur.txt       google-chrome            (pacman systems only)
  apt.txt       thunderbird qbittorrent vlc
  dnf.txt       …
  zypper.txt    MozillaThunderbird …     (names differ per distro, hence separate files)
  nix.txt       …
```

| Manager | Installed check | Install |
|---|---|---|
| pacman | `pacman -Q` | `omarchy-pkg-add` on Omarchy, else `pacman -S --needed` |
| AUR | `pacman -Q` | `omarchy-pkg-aur-add` on Omarchy, else `yay`/`paru` |
| apt | `dpkg-query` | `apt-get install -y` (one `apt-get update` per run) |
| dnf / zypper | `rpm -q --whatprovides` | `dnf install -y` / `zypper install` |
| nix | `nix profile list` | `nix profile install nixpkgs#<pkg>` |

A missing manifest means "nothing to install on this manager". A comment in the file can
explain extra repos a distro needs (see `features/mise/packages/apt.txt`).

Honest scope: Omarchy only runs on Arch, so pacman/AUR is the path that gets real use. The
other managers exist so portable features (terminal, dev tools, apps) can follow you to a
non-Omarchy machine, and CI checks them with a dry run on each distro.

## State

Kept outside the repo in `~/.local/state/omarchy-setup/` (override: `DOTCTL_STATE_DIR`):

```
transactions/<id>/journal     LINK/UNLINK/BACKUP/SERVICE/MIGRATION lines, in order
transactions/<id>/backup/     originals of replaced files, by path under $HOME
transactions/<id>/displaced/  files changed after install, saved during a rollback
last                          most recent transaction
links.manifest                links owned by the repo (used to remove stale ones)
migrations.done               migrations applied on this machine
profile                       profile used last
```

## Security model

- The repo contains configs only. No tokens, keys, emails or names (`git/config` is written by
  the Omarchy installer from what you type during setup).
- Secrets come from env vars, `pass`, or a GPG-encrypted file outside the repo ([secrets.md](secrets.md)).
- Third-party code is pinned to a commit (e.g. the Better Displays plugin in `omarchy-shell`).
- CI: gitleaks on every push, a personal-data check in `ci/syntax.sh`, signed release tags.
- `install.sh` refuses to run as root; `sudo` is used only by package and system-service steps.
