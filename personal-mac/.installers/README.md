# Vendored installers

Installer scripts for tools that ship no Homebrew formula or cask, only a `curl … | sh` one-liner. The scripts are checked in here so they are reviewed and pinned rather than fetched and executed sight-unseen at apply time.

`.chezmoidata/installers.toml` declares each one — its prerequisites, its environment, and where the copy came from — and `.chezmoiscripts/run_after_run-installers.py.tmpl` runs them.

This directory is invisible to chezmoi: source entries whose names begin with `.` are ignored (except the `.chezmoi*` specials), so nothing here is ever written into `$HOME`.

## Adding an installer

Vendor the script rather than piping it from the network, so the thing that runs is the thing that was reviewed:

```sh
mkdir -p <tool>
curl -fsSL -o <tool>/install.sh https://example.com/install.sh
```

Read it before declaring it. Note anything it does to a chezmoi-managed file or anything interactive it expects — those are what the entry's `env` and `preflight` fields exist to handle. Then add the entry to `.chezmoidata/installers.toml` and a row to the table below.

## Refreshing a vendored script

The runner fingerprints the script's contents, so replacing the file is all it takes to make the installer re-run on the next apply. Re-download it, then read `git diff` with the same eyes you would give a `curl | sh` — an upstream change can invalidate the entry's `env` settings.

## Contents

None yet.
