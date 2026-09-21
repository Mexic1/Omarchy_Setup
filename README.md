# Omarchy_Setup

My Omarchy setup: config tweaks, packages and an install script to rebuild it on a fresh machine.

Only the changes on top of Omarchy's defaults live here, so Omarchy updates keep improving everything else.
No personal data or secrets are stored in this repo.

## Quickstart

1. Install Omarchy from the ISO ([omarchy.org](https://omarchy.org)) and log in.
2. Clone and run:

   ```bash
   git clone https://github.com/Mexic1/Omarchy_Setup ~/Projects/Omarchy_Setup
   cd ~/Projects/Omarchy_Setup
   ./install.sh --dry-run -p laptop-convertible   # preview
   ./install.sh -p laptop-convertible             # apply
   ```

3. Log out and back in (or `hyprctl reload`) to pick up everything.

`install.sh` is safe to re-run: it only changes what differs from the repo, backs up
every file it replaces, and rolls back automatically if a step fails.

On plain Arch without Omarchy, `./install.sh --bootstrap-omarchy` runs the official Omarchy installer first.
On other distros the portable features (kitty, mise, apps…) still install; Omarchy-only ones are skipped.

## Profiles

| Profile | For | Features |
|---|---|---|
| `default` | any Omarchy machine | hyprland, omarchy-shell, kitty, herdr, mise, apps |
| `laptop-convertible` | 2-in-1 laptop + HDMI monitor | default + tablet-mode, voxtype, monitor layout |
| `ci` | automated tests | kitty |

The profile you install with is remembered for later runs. `bin/dotctl list` shows all features.

## Day to day

```bash
bin/dotctl status      # what drifted from the repo
bin/dotctl plan        # what install would change
bin/dotctl install     # apply the repo
bin/dotctl verify      # health check
bin/dotctl adopt       # a program rewrote a linked file: keep its version in the repo
bin/dotctl rollback    # undo the last install
bin/dotctl new <name>  # add an app as a new feature module
bin/dotctl doctor      # diagnose problems
```

Configs are **symlinks** into this repo, so tweaking `~/.config/hypr/input.lua` edits the repo copy.
Commit it, and every machine gets it on the next `git pull && ./install.sh`.

## Layout

```
install.sh            entry point → bin/dotctl install
bin/dotctl            CLI: install, plan, verify, status, adopt, rollback, new, doctor
scripts/lib/          internals: packages, links, transactions, features, secrets
features/<name>/      one module per app: feature.sh, home/, packages/<manager>.txt
features/_template/   copied by `dotctl new`
profiles/<name>/      feature lists + per-machine file overrides (home/)
migrations/           one-off changes for machines on an older version
ci/                   scripts CI runs (lint, syntax, dry-run matrix, smoke test, signatures)
docs/                 architecture, features, secrets, git flow, rollback, troubleshooting
secrets.example       names of secrets features may need (values never committed)
```

## Docs

- [Architecture](docs/architecture.md): install flow, symlink plan, package layer, state
- [Adding an app](docs/features.md): the feature module contract, step by step
- [Secrets](docs/secrets.md)
- [Updates & rollback](docs/updates-and-rollback.md)
- [Git flow & releases](docs/git-flow.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)
