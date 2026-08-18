# Vendored installers

Installer scripts for tools that ship no Homebrew formula or cask, only a `curl … | sh` one-liner. The scripts are checked in here so they are reviewed and pinned rather than fetched and executed sight-unseen at apply time.

`.chezmoidata/installers.toml` declares each one — its prerequisites, its environment, and where the copy came from — and `.chezmoiscripts/run_after_run-installers.py.tmpl` runs them.

This directory is invisible to chezmoi: source entries whose names begin with `.` are ignored (except the `.chezmoi*` specials), so nothing here is ever written into `$HOME`.

## Refreshing a vendored script

The runner fingerprints the script's contents, so replacing the file is all it takes to make the installer re-run on the next apply.

```sh
curl -fsSL -o graft/install.sh https://grafana.github.io/plugin-graft/install.sh
git diff -- graft/install.sh   # read it before applying
```

Review the diff with the same eyes you would give a `curl | sh` — the entry's `env` settings in `installers.toml` exist to defuse specific behaviors (Graft, for example, appends to the profile of `$SHELL`), and an upstream change can invalidate them.

## Contents

| Script             | Upstream                                            |
|--------------------|-----------------------------------------------------|
| `graft/install.sh` | <https://grafana.github.io/plugin-graft/install.sh> |
