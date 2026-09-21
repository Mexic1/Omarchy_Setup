# Feature modules

A feature is one app or concern. The installer knows nothing about specific apps: adding
one means adding a folder, never editing `bin/dotctl`.

```
features/<name>/
  feature.sh            metadata + optional hooks (required)
  home/                 files linked into $HOME at the same relative path (optional)
  packages/<pm>.txt     pacman, aur, apt, dnf, zypper, nix; one package per line, # comments (optional)
```

## Metadata

| Variable | Meaning |
|---|---|
| `FEATURE_NAME` | must equal the folder name |
| `FEATURE_DESC` | one line for `dotctl list` |
| `FEATURE_REQUIRES` | `omarchy` (skipped elsewhere) or `any` |
| `FEATURE_DEPENDS=()` | features applied before this one |
| `FEATURE_SERVICES_USER=()` / `FEATURE_SERVICES_SYSTEM=()` | systemd units to enable and start |

## Hooks

All optional; all must be **idempotent** (check, then act).

| Hook | Runs | Typical use |
|---|---|---|
| `feature_pre_install` | after packages, before links | `secret_require`, create directories |
| `feature_post_install` | after links, before services | clone plugins, download models, set default apps |
| `feature_verify` | in `dotctl verify` | return non-zero if the feature isn't working |

Rules for hooks:

- Wrap every system-changing command in `run` so `--dry-run` only prints it.
- Call `changed` right before you act. `install --check` counts these, so a hook that acts on
  every run fails the idempotency test in CI.
- Helpers available: `run`, `changed`, `info`, `warn`, `die`, `pkg_is_installed`, `secret_get`,
  `secret_require`, plus `$FEATURE_DIR`, `$REPO_DIR`, `$DRY_RUN`, `$IS_OMARCHY`, `$PKG_MANAGER`.
- Pin anything downloaded: a git commit, or a URL plus SHA-256 checked with `sha256sum -c`.

## Adding an app, step by step

Example: an `obs` feature.

```bash
bin/dotctl new obs
```

1. **Metadata:** edit `features/obs/feature.sh` (description, `FEATURE_REQUIRES`).
2. **Packages:** put `obs-studio` in `packages/pacman.txt` (and the other managers you care
   about); delete the manifest files you don't need.
3. **Config:** copy only files you changed from the default:
   ```bash
   mkdir -p features/obs/home/.config/obs-studio
   cp ~/.config/obs-studio/global.ini features/obs/home/.config/obs-studio/
   ```
   Never copy app state (caches, databases, cookies, history); `.gitignore` blocks the usual ones.
4. **Hooks** (only if needed), e.g. enabling a plugin or downloading something.
5. **Profile:** add `obs` to `FEATURES` in `profiles/default/profile.conf` (or a machine profile).
6. **Try it:**
   ```bash
   bin/dotctl plan --only obs      # preview
   bin/dotctl install --only obs   # apply just this feature
   bin/dotctl install --check      # must print "nothing to change"
   ci/lint.sh && ci/syntax.sh
   ```
7. Branch `feature/obs`, PR to `develop`, changelog entry under *Unreleased → Added*.

## Finding what you changed

To see which Omarchy-managed files differ from the stock defaults:

```bash
cd /usr/share/omarchy/config
find . -type f | while read -r f; do cmp -s "$f" ~/.config/"$f" || echo "${f#./}"; done
```

Files that show up but aren't links into this repo are candidates for a feature.
