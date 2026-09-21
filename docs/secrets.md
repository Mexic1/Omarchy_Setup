# Secrets

**Nothing secret or personal is ever committed.** That includes tokens, passwords, SSH/GPG
keys, Wi-Fi keys, emails and names. `.gitignore` blocks the common file types, `ci/syntax.sh`
rejects identity lines and private keys, and gitleaks scans every push, including history.

## How features get secrets

A hook calls `secret_get NAME` (or `secret_require NAME...` in `feature_pre_install`, so a
missing secret stops the install before anything changes). Lookup order:

| # | Source | Set up |
|---|---|---|
| 1 | Environment | `GH_TOKEN=... ./install.sh` |
| 2 | `pass` | `pass insert omarchy-setup/GH_TOKEN` |
| 3 | Local env file | `~/.config/omarchy-setup/secrets.env`, `chmod 600` |
| 4 | GPG-encrypted env file | `~/.config/omarchy-setup/secrets.env.gpg` |

`secrets.example` lists every name in use, with no values. When a feature starts needing a
secret, add its name there in the same PR.

### GPG file

```bash
cp secrets.example /tmp/secrets.env && $EDITOR /tmp/secrets.env
gpg --encrypt --recipient <your-key-id> -o ~/.config/omarchy-setup/secrets.env.gpg /tmp/secrets.env
shred -u /tmp/secrets.env
```

Keep the GPG key itself (and SSH keys) in a password manager or on a hardware key, not in this repo.
On a new machine, restore the key first, then run `./install.sh`.

### External vault

For 1Password, Bitwarden and the like, export the value into the environment for the run:

```bash
GH_TOKEN=$(op read "op://Private/GitHub/token") ./install.sh
```

## Personal identity

Omarchy's installer asks for your name and email and writes `~/.config/git/config`, so that file
is intentionally **not** in this repo.

## If a secret was committed

1. Revoke or rotate it first. Removing it from git doesn't make it safe again.
2. Remove it from history (`git filter-repo --invert-paths --path <file>`), force-push, and ask
   anyone with a clone to re-clone.
