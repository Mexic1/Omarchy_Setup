# Troubleshooting

Start with:

```bash
bin/dotctl doctor      # environment, repo, state, broken links
bin/dotctl status      # drift
bin/dotctl verify      # what exactly is unhealthy
bin/dotctl install -v  # re-run showing every command
```

## Install checklist (fresh machine)

Go down the list; the first unchecked item is usually the problem.

- [ ] Omarchy is installed and you're logged into the Hyprland session (`omarchy version`)
- [ ] Internet works (`ping -c1 archlinux.org`)
- [ ] You're your normal user, not root (`whoami`)
- [ ] `sudo true` works (package installs need it)
- [ ] The repo is complete and clean (`git status`, `git log -1`)
- [ ] The profile exists (`bin/dotctl list`) and is the one you meant (`-p <name>`)
- [ ] The dry run looks right (`./install.sh --dry-run -p <name>`)
- [ ] Secrets needed by your features are available (`secrets.example`)
- [ ] After install, `bin/dotctl verify` passes
- [ ] `bin/dotctl install --check` prints "nothing to change"
- [ ] `hyprctl configerrors` is empty, and the bar looks right (`omarchy restart shell`)

## Common problems

| Symptom | Cause | Fix |
|---|---|---|
| `run as your normal user, not root` | ran with `sudo ./install.sh` | run `./install.sh`; it calls sudo itself |
| `X is provided by both A and B` | two features ship the same file | move the file to one feature, or override it in a profile's `home/` |
| `X is a directory; expected a file` | a directory is where a config file should be link | move the directory aside, re-run |
| `unknown feature` / `unknown profile` | typo, or folder missing `feature.sh`/`profile.conf` | `bin/dotctl list` |
| AUR package fails | no `yay`/`paru`, or AUR down | `omarchy pkg aur add <pkg>` by hand, re-run install |
| `status` shows **drifted** | a program or `omarchy update` rewrote the file | `bin/dotctl adopt` to keep it, or `bin/dotctl install` to restore the repo version |
| `status` shows **foreign** | the path links somewhere else (another dotfiles tool?) | remove that link, re-run install (it's backed up) |
| `doctor` shows **broken links** | the repo was moved or renamed | move it back, or re-run `./install.sh` from the new place |
| `another dotctl run is in progress` | a run is still going, or crashed holding the lock | wait, or check `pgrep -f dotctl`; the lock is released when the process exits |
| Service not enabled | no systemd user session (SSH, container) | run install from the desktop session |
| `install --check` never reaches "nothing to change" | a hook acts on every run | make the hook check before calling `changed`/`run` |
| Hyprland errors after install | a linked `.lua` has a mistake | `hyprctl configerrors`, fix the file in the repo, or `bin/dotctl rollback` |
| Bar missing after install | bad `shell.json` or plugin | `jq . ~/.config/omarchy/shell.json`, `omarchy restart shell`, or roll back |
| Wrong monitor layout | wrong profile for this machine | install with the right `-p`, or add a profile with its own `hypr/monitors.lua` |

## Recovering

```bash
bin/dotctl rollback                 # undo the last run
bin/dotctl history                  # pick an older one: bin/dotctl rollback <id>
ls ~/.local/state/omarchy-setup/transactions/<id>/backup/   # originals, by path
```

Still stuck? Open an issue with the *Install problem* template and paste the output of
`bin/dotctl doctor` and `bin/dotctl install -v --dry-run`.
