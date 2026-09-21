# Contributing

This is a personal setup, but it's run like a small project so that changes never break a
machine being restored.

## Workflow

1. Branch from `develop`: `feature/<name>`, or `hotfix/<version>` from `main` ([git flow](docs/git-flow.md)).
2. Make the change. Adding an app = a new feature module ([guide](docs/features.md)): `bin/dotctl new <name>`.
3. Test locally:
   ```bash
   ci/lint.sh && ci/syntax.sh      # needs shellcheck, shfmt, jq, luac, python3
   bin/dotctl plan
   bin/dotctl install
   bin/dotctl install --check      # must print "nothing to change"
   bin/dotctl verify
   ```
4. Add a `CHANGELOG.md` line under *Unreleased*.
5. Open a PR; fill in the template. Merge when CI is green and the checklist is done.

## Conventions

- **Only diffs from defaults.** Copy a file into a feature only if you changed it.
- **One owner per file.** Machine-specific files go in a profile's `home/`.
- **No personal data or secrets**, ever ([secrets](docs/secrets.md)).
- **Idempotent hooks**: check first, `changed`, then `run ...`.
- **Pin third-party code** to a commit or checksum.
- Bash: `set -Eeuo pipefail` in entry points, 2-space indent, `shfmt -i 2 -ci -bn`, shellcheck clean.
- Commits: imperative, short subject (`Add obs feature`, `Fix voxtype model check`).

## Tools

```bash
omarchy pkg add shellcheck shfmt jq lua
```
