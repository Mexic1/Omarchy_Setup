# Migrations

One-off changes for machines that already ran an older version of this repo,
e.g. deleting a file a feature no longer ships, or renaming a setting that
Omarchy moved. Fresh installs mark every migration as done without running it,
because the configs already contain the end result.

- Name: `<unix-timestamp>-<what-it-does>.sh`, e.g. `1790000000-remove-old-waybar-config.sh`
  (create with `touch migrations/$(date +%s)-describe-change.sh`).
- Plain bash, run once per machine by `dotctl install`, in name order, after links and hooks.
  `$REPO_DIR` and `$HOME` are set.
- Must be idempotent and must back up anything it deletes, because `dotctl rollback`
  cannot undo migrations:
  `cp -a ~/.config/foo ~/.config/foo.bak.$(date +%s)`
- Applied migrations are listed in `~/.local/state/omarchy-setup/migrations.done`.
- A change that needs a migration is a breaking change: bump the MAJOR version.
