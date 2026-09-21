## What changes on the desktop

<!-- What will I notice after pulling this and running ./install.sh? -->

## Type

- [ ] New feature module
- [ ] Config tweak (PATCH)
- [ ] Installer / tooling
- [ ] Fix
- [ ] **Breaking** (renamed/removed feature, moved file, migration → MAJOR)

## Tested on

<!-- Machine type and profile, e.g. "2-in-1 laptop, laptop-convertible, Omarchy 4.0.4" -->

## Checklist

- [ ] `ci/lint.sh && ci/syntax.sh` pass
- [ ] `bin/dotctl install` works and `bin/dotctl verify` passes
- [ ] `bin/dotctl install --check` prints "nothing to change" (idempotent)
- [ ] Configs contain only my changes from the defaults, no app state
- [ ] No secrets or personal data (names, emails, tokens, keys, hostnames)
- [ ] Third-party downloads are pinned (commit or checksum)
- [ ] Hooks use `run` and `changed`
- [ ] `CHANGELOG.md` updated under *Unreleased*
- [ ] Docs updated if behaviour or commands changed
