# Updates & rollback

## Updating a machine

```bash
cd ~/Projects/Omarchy_Setup
bin/dotctl status          # anything drifted locally? adopt or discard it first
git pull
bin/dotctl plan            # review
bin/dotctl install         # apply
```

To pin a machine to a release instead of the tip of `main`: `git checkout v1.2.0 && bin/dotctl install`.

## What makes an apply safe

| Mechanism | Where |
|---|---|
| **Plan first:** all links are collected and conflicts (two owners, a directory in the way) stop the run before anything changes | `link_collect` |
| **Atomic swap:** the original is copied to the backup, then a temp link is renamed over it (`mv -T`). The target path is never missing, even on power loss | `link_apply_one` |
| **Journal:** every change is written to `transactions/<id>/journal` as it happens | `txn_record` |
| **Auto-rollback:** any failing step (package, hook, link) undoes the journal of the current run | `_on_exit` in `bin/dotctl` |
| **Lock:** two installs can't run at once | `flock` |
| **Idempotent steps:** a second run changes nothing; CI enforces it with `install --check` | every phase |

## Rollback

```bash
bin/dotctl history               # list runs
bin/dotctl rollback              # undo the most recent run not yet rolled back
bin/dotctl rollback <id>         # undo a specific run (undo newer ones first)
bin/dotctl rollback --dry-run    # show what it would do
```

What rollback does, newest change first:

- removes links it created, and restores the backed-up originals;
- re-creates links that run removed;
- disables services that run enabled.

It doesn't:

- **uninstall packages.** Removing packages can take dependencies other things need; remove
  them yourself with `pacman -Rns` if you want.
- **undo migrations** (migrations must back up what they touch; see `migrations/README.md`).
- **discard your edits.** A file changed after the install is saved to `transactions/<id>/displaced/`
  before the original comes back.

### Verification after a rollback

`dotctl rollback` checks this automatically and prints `rolled back and verified`. To check by hand:

```bash
bin/dotctl history                          # the run shows "rolled back"
ls -l ~/.config/kitty/kitty.conf            # a regular file again (or the link you had before)
hyprctl reload && hyprctl configerrors      # Hyprland still parses its config
omarchy restart shell                       # bar comes back with the restored shell.json
```

### Full reset to Omarchy defaults (last resort)

```bash
bin/dotctl rollback            # repeat until history shows nothing applied
omarchy refresh hyprland       # Omarchy backs up and restores its own defaults
omarchy refresh shell
```

## Migrations

For machines already set up by an older version, when a change can't be expressed as
"the repo now has this file". Examples: deleting a file a feature stopped shipping, or
moving a setting Omarchy renamed. See `migrations/README.md`. A release with a migration is a
MAJOR version bump.

## After an Omarchy update

Omarchy migrations sometimes rewrite files in `~/.config` with `sed -i`, which replaces our link
with a regular file. After `omarchy update`:

```bash
bin/dotctl status      # "drifted" files
git -C ~/Projects/Omarchy_Setup diff --no-index features/<f>/home/<path> ~/<path>   # what changed
bin/dotctl adopt       # keep Omarchy's change (then commit), or
bin/dotctl install     # put the repo version back
```
