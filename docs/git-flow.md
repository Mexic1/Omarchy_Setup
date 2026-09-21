# Git flow & releases

## Branches

| Branch | Purpose | Branches from | Merges into |
|---|---|---|---|
| `main` | What machines install. Always releasable; every commit on it is tagged | – | – |
| `develop` | Integration of finished work, tested on at least one real machine | `main` | `release/*` |
| `feature/<name>` | One feature module or change (`feature/obs`, `feature/hypr-gestures`) | `develop` | `develop` |
| `release/<x.y.z>` | Freeze: bump `VERSION`, finalize `CHANGELOG.md`, only fixes | `develop` | `main` **and** `develop` |
| `hotfix/<x.y.z>` | Urgent fix to what's installed (e.g. broken after an Omarchy update) | `main` | `main` **and** `develop` |

```
main     ──●───────────────●──────────●──   v0.1.0   v0.2.0   v0.2.1
            \             / \        /
release/     \      ●────●   \      /
develop  ─────●──●──●─────────●────●──
               \   /  \   /       /
feature/        ●─●    ●─●       /
hotfix/                    ●────●
```

**For a single-maintainer repo** this is more ceremony than needed. The lightweight variant
keeps the same rules on `main` (PRs, CI, signed tags), drops `develop` and `release/*`, and
branches `feature/*` and `hotfix/*` from `main`. Switch whenever you like: nothing in the tooling
depends on `develop` existing.

## Branch protection (GitHub → Settings → Branches)

`main` and `develop`:
- Require a pull request; no direct pushes, no force pushes, no deletion.
- Require status checks: `Lint & syntax`, `Secret scan`, `Smoke test`, all `Dry run` jobs.
- Require branches to be up to date; require linear history on `main` (squash or rebase merges).
- Require signed commits (optional but recommended; see [Signing](#signing)).

## Code review rules

A PR is mergeable when:

1. CI is green (lint, syntax, secret scan, dry-run on every distro, smoke test).
2. `bin/dotctl install --check` prints "nothing to change" on a machine that ran the branch
   (the idempotency proof), and the PR says which machine/profile it was tested on.
3. New configs contain only changes from the defaults, and no state, caches, or personal data.
4. Hooks are idempotent, use `run`/`changed`, and pin anything downloaded.
5. `CHANGELOG.md` has an entry under *Unreleased* (skip only for docs/CI-only changes).
6. Breaking changes (renamed/removed feature, moved file, needs a migration) are called out.

Solo: review your own diff in the PR view the next day before merging. It catches a surprising
amount, and the checklist in the PR template does the rest.

## Versioning (SemVer for a dotfiles repo)

| Bump | When | Examples |
|---|---|---|
| **MAJOR** | Re-running install on an existing machine needs attention | feature renamed/removed, file moved to another feature, a migration, dropped distro support, changed CLI flags |
| **MINOR** | New capability, existing machines just re-run install | new feature module, new profile, new `dotctl` command |
| **PATCH** | Tweaks and fixes | config value change, package added to a manifest, bug fix, docs |

## Changelog policy

[Keep a Changelog](https://keepachangelog.com) format in `CHANGELOG.md`:

- Every PR adds a line under `## [Unreleased]` in `Added`, `Changed`, `Fixed`, `Removed` or
  `Security`, written for "future me restoring a machine" (what changes on the desktop).
- Breaking entries start with **BREAKING:** and say what to do.
- The release branch renames `Unreleased` to `## [x.y.z] - YYYY-MM-DD` and opens a fresh `Unreleased`.

## Releasing

```bash
git switch develop && git pull
git switch -c release/0.2.0
echo 0.2.0 > VERSION            # + move Unreleased → [0.2.0] in CHANGELOG.md
git commit -am "Release 0.2.0"
# PR release/0.2.0 → main, merge after CI
git switch main && git pull
git tag -s v0.2.0 -m "v0.2.0"    # signed tag
git push origin v0.2.0
git switch develop && git merge --no-ff main && git push
```

Pushing the tag runs `.github/workflows/release.yml`, which verifies the tag signature, checks
that `VERSION` and `CHANGELOG.md` match, and publishes a GitHub release with notes, a source
tarball and `SHA256SUMS`.

Hotfix: the same, from `main` into `hotfix/0.2.1`, PATCH bump, merged into both `main` and `develop`.

## Signing

SSH signing (no GPG needed, and no email in the repo):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
# Let CI verify it:
echo "maintainer $(cat ~/.ssh/id_ed25519.pub)" > .github/allowed_signers
```

Also add the key on GitHub as a **Signing key** (Settings → SSH and GPG keys) so commits show
as *Verified*. Check locally with `ci/verify-signatures.sh v0.2.0`.
