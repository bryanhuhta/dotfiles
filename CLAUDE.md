# Claude Guidelines — Dotfiles

This repository manages dotfiles using [chezmoi](https://www.chezmoi.io/). Read this file in full before making any changes.

---

## Neovim Version

The target Neovim version is **0.12**. Commands and APIs from older versions may not apply. In particular:

- `:LspLog` does not exist — use `:lua vim.cmd("edit " .. vim.lsp.get_log_path())` to open the LSP log file, or `:lua print(vim.lsp.get_log_path())` to find it
- `:LspInfo` does not exist — use `:lua print(vim.inspect(vim.lsp.get_clients()))` or `:checkhealth lsp`
- LSP is configured via `vim.lsp.config()` / `vim.lsp.enable()` (0.11+ API), not `require("lspconfig")`
- Always suggest commands and APIs that are valid in Neovim 0.12

---

## Absolute Rules

**Never do any of the following:**

- Apply dotfile changes (`chezmoi apply`, `chezmoi update`)
- Run `git commit`, `git push`, or any git command that changes repository state
- Edit target files directly (e.g. `~/.zshrc`, `~/.gitconfig`) — always edit the source file in the chezmoi source directory
- Add secrets, credentials, tokens, or passwords to any file
- Run any command that changes system state beyond creating or editing files in the source directory

After making changes, always tell the user to run `chezmoi diff` to review and `chezmoi apply` to apply when ready.

---

## Secrets

Secrets live in the macOS Keychain, never in this repository. Scripts read them at runtime with `security find-generic-password`. `README.md` keeps the authoritative list of Keychain items and their rotation steps — when adding or removing a Keychain-read secret, update that list.

---

## What Is chezmoi

chezmoi manages dotfiles by maintaining a **source directory** (default: `~/.local/share/chezmoi`) that is a git repository. Files in this directory are transformed and written to their target locations (typically `$HOME`). The source directory is where all edits happen.

The source directory location may differ between machines, but the user will always launch Claude from within it. Use the current working directory as the source directory root.

Reference: https://www.chezmoi.io/user-guide/command-overview/

---

## Source Directory Naming Conventions

Files in the source directory use prefixes and suffixes to encode how chezmoi should handle them. chezmoi decodes these names to determine the target path and file behavior.

### Common Prefixes

| Prefix       | Effect                                                   |
|--------------|----------------------------------------------------------|
| `dot_`       | Replaces `dot_` with `.` in the target path              |
| `private_`   | Removes group and world permissions (mode `0600`/`0700`) |
| `symlink_`   | Creates a symbolic link instead of a regular file        |
| `executable_`| Adds executable permission to the target                 |
| `readonly_`  | Removes write permission from the target                 |
| `run_`       | Treats the file as a script to run on apply              |
| `create_`    | Creates the target only if it does not already exist     |

Prefixes can be combined and are applied in order. Example: `private_dot_config` → target is `.config` with restricted permissions.

### Suffixes

| Suffix  | Effect                                      |
|---------|---------------------------------------------|
| `.tmpl` | File contents are rendered as a Go template |

### Examples

| Source path                    | Target path         |
|--------------------------------|---------------------|
| `dot_zshrc.tmpl`               | `~/.zshrc`          |
| `dot_gitconfig.tmpl`           | `~/.gitconfig`      |
| `private_dot_config/nvim/`     | `~/.config/nvim/`   |

Reference: https://www.chezmoi.io/reference/source-state-attributes/

---

## Machine Configuration

Each machine has a local `chezmoi.toml` config file that is **not tracked in this repository**. It provides machine-specific values (such as identity and profile) that templates reference via `.variableName` syntax.

See `README.md` for the current list of supported configuration variables. When adding a new template variable, update `README.md` to document it.

To inspect what data is currently available to templates on the active machine:

```sh
chezmoi data
```

---

## Profiles

There are two profiles: `personal-mac` and `work-mac`. Each has its own source directory at the top of the repository; the machine-local config sets `sourceDir` to select one, and `profile` to name it.

### Per-profile source directories (the Mac profiles)

`personal-mac/` and `work-mac/` are self-contained chezmoi source directories at the top of the repository. The machine-local `chezmoi.toml` points `sourceDir` at one of them, so chezmoi never sees the other profile's files at all.

Inside a profile directory:

- There are **no `.profile` conditionals**. The directory is the condition. A file that needs to differ per profile simply differs between the two directories, and a file only one profile wants exists only in that directory.
- It owns its own `.chezmoiignore`, `.chezmoidata.toml`, `.chezmoidata/`, `.chezmoiexternal.toml`, and `.chezmoiscripts/`. The root copies of those files do not apply.
- Templating is reserved for machine data (`.git.name`, `.git.email`, `hasKey .git "signingkey"`). If a file has no template actions left after de-templating, drop its `.tmpl` suffix.
- Repository-root assets (`claude-home/`, `zed_settings.json`, the Docker build contexts) live one level up. Reach them with `{{ .chezmoi.sourceDir | dir }}` in a template and `$(dirname $(chezmoi source-path))` in a script — a bare `.chezmoi.sourceDir` resolves inside the profile directory and silently produces a dangling symlink or a missing build context.
- Scripts belong in `.chezmoiscripts/`, not at the top level, so they run without also being written into `$HOME`.

When changing something that both Macs share, make the edit in both directories. There is deliberately no shared layer between them.

### The repository root

Nothing applies from the repository root: it holds the two profile directories, the shared assets (`claude-home/`, `zed_settings.json`, the Docker build contexts), and the documentation. Root `.chezmoiignore` is a single `{{ fail }}` — chezmoi's default source directory is the repository root, so a machine that forgets `sourceDir` would otherwise apply `personal-mac/` and `work-mac/` into `$HOME` as literal directories.

### Adding a profile

Create a new top-level directory, populate it, and point the new machine's `sourceDir` at it. Do not reintroduce `{{ if eq .profile ... }}` gating — there are no profile conditionals anywhere in this repository, and profile differences are expressed by which directory a file lives in. `.profile` remains in the machine config as a label (it is what root `.chezmoiignore` reports in its error), not as a switch templates branch on.

The one rule that still bites: **`.chezmoiexternal.toml` and `.chezmoidata*` are not covered by `.chezmoiignore`.** For ordinary files and scripts, chezmoi checks the ignore list *before* evaluating a template's contents, so an ignored template never runs. Those two are executed during the source-directory walk, before `.chezmoiignore` is read. If one of them calls something side-effecting or environment-dependent (`onepasswordRead`, `output`, `exec` — anything that shells out or depends on machine state), no ignore entry can stop it from running. Note that `chezmoi cat` and `chezmoi execute-template` bypass ignores entirely, so neither is evidence about what `apply` would do.

Profiles are intentionally decoupled from hostnames or other machine identifiers. Never gate behavior on `.chezmoi.hostname` or similar — the profile directory exists precisely so config stays valid when hardware changes.

---

## Templates

Only make a file a template (add the `.tmpl` suffix) when it needs:
- Conditional rendering based on profile or other config data
- Interpolated values from the machine config

Plain files that are identical across all machines should remain plain files.

### Template Syntax

Templates use Go's `text/template` syntax. Data from the machine config is available as `.variableName` (top-level) or `.section.variableName` (nested). chezmoi also provides built-in variables under `.chezmoi.*`.

Common patterns:

```
# Interpolate a value
email = {{ .git.email }}

# Conditional on machine data (there are no profile conditionals — see Profiles)
{{- if hasKey .git "signingkey" }}
	signingkey = {{ .git.signingkey }}
{{- end }}
```

The `-` in `{{-` and `-}}` trims surrounding whitespace/newlines, which is important for producing clean output.

Reference: https://www.chezmoi.io/user-guide/templating/

---

## Workflows

### Editing an Existing File

1. Edit the source file directly in the chezmoi source directory
2. If it is a template, verify it renders correctly (see Testing Templates below)
3. Review the diff: `chezmoi diff`
4. Tell the user to apply when ready: `chezmoi apply`

### Adding a New Dotfile

Use `chezmoi add` to bring an existing target file into the source directory:

```sh
chezmoi add ~/.some_config_file
```

chezmoi automatically applies the correct naming prefixes. To add as a template:

```sh
chezmoi add --template ~/.some_config_file
```

Only use `.tmpl` if the file genuinely needs conditional rendering or data interpolation.

### Testing Templates

Before applying, verify a template renders correctly:

```sh
# Render a source template file directly
chezmoi execute-template < dot_zshrc.tmpl

# Render by target path
chezmoi cat ~/.zshrc
```

### Validating Changes

Always validate before telling the user to apply.

| Command              | Purpose                                                         |
|----------------------|-----------------------------------------------------------------|
| `chezmoi diff`       | Show what `apply` would change (diff between source and target) |
| `chezmoi status`     | Short summary of which files are out of sync                    |
| `chezmoi verify`     | Exit non-zero if any target is out of sync with the source      |
| `chezmoi cat <path>` | Print the rendered content of a managed file                    |

---

## Utility Scripts

Utility scripts live in `dot_local/bin/` and are installed to `~/.local/bin/`. When adding a new utility script, **always ask the user** whether it is for personal use, work use, or both — this determines whether the script needs profile gating.

### File naming

The source file must be named `executable_<name>` so chezmoi sets the executable bit. Example: `dot_local/bin/executable_myscript` → `~/.local/bin/myscript`.

### Required structure

Every script must follow this pattern:

```bash
#!/bin/bash
## Short description of what the script does.
##
## More detail if needed.
##
## Usage: scriptname [-h] [other options...]
##   -h    Print this help message

set -euo pipefail

if [[ "${1:-}" == "-h" ]]; then
  grep '^##' "$0" | sed -E 's/^## ?//'
  exit 0
fi

# ... rest of script
```

Key requirements:

- **`-h` flag is mandatory** — every script must support `-h` to print its help message
- **Help text is embedded as `##` comments** at the top of the file, immediately after the shebang
- **Help extraction** uses `grep '^##' "$0" | sed -E 's/^## ?//'` — the `-E` flag is required for macOS compatibility
- **`set -euo pipefail`** must appear before any logic
- The `-h` check must come before all other argument parsing

### Profile-specific scripts

If a script is only for one profile, ask the user whether to gate it with a chezmoi template or simply not install it on other machines. For template gating, the file would need a `.tmpl` suffix and conditional rendering.

---

## Python Scripts

Some chezmoi scripts are easier to get right in Python than in bash — the installer runner is one. Every Python script in this repository, `.chezmoiscripts/` runners included, follows these rules without exception.

- **Always `#!/usr/bin/python3`** — the system interpreter shipped with the Xcode Command Line Tools. Never `#!/usr/bin/env python3`, and never a Homebrew, pyenv, asdf, or virtualenv interpreter. A chezmoi script runs during `apply` with whatever environment the machine happens to have; the system interpreter is the only one guaranteed to be present, guaranteed to predate Homebrew, and immune to a half-finished `brew upgrade python`.
- **Standard library only. NEVER import a third-party library, under any circumstances.** No `pip install`, no vendored packages, no virtualenv, no exceptions "just this once". These scripts run on machines that may have nothing installed yet, so a third-party import is a bootstrap failure waiting to happen. If something appears to require a third-party library, it does not belong in a chezmoi script — solve it another way or raise it with the user.
- **Target the system interpreter's version.** Check it with `/usr/bin/python3 --version` (currently 3.9) and write code that runs there. macOS moves that version on its own schedule, so never assume anything newer is available.
- **Stay on the paved path.** Prefer the boring, long-stable parts of the stdlib: `subprocess.run`, `pathlib`, `json`, `argparse`, `os`, `shutil`, `hashlib`. Avoid APIs that are newly added, provisional, or deprecated, and avoid clever corners of the stdlib when an obvious call does the same job. These scripts are read years later on an unfamiliar machine — predictable beats modern.
- **Check that it renders and parses** before telling the user to apply:

  ```sh
  chezmoi execute-template < .chezmoiscripts/<script>.py.tmpl \
    | /usr/bin/python3 -c 'import ast, sys; ast.parse(sys.stdin.read())'
  ```

---

## Vendored Installers

Tools with no Homebrew formula or cask are installed from a vendored copy of their `curl | sh` installer, never from the network at apply time.

- The script lives in `<profile>/.installers/<tool>/`. Entries starting with `.` are invisible to chezmoi, so nothing there reaches `$HOME`.
- `<profile>/.chezmoidata/installers.toml` declares each installer: `name`, `description`, `script` (relative to `.installers/`), `upstream`, `requires` (commands that must be on `PATH`), and optionally `preflight` (commands that must exit 0), `hint`, and `env`.
- `<profile>/.chezmoiscripts/run_after_run-installers.py.tmpl` renders the list into a Python script and runs it, under the rules in **Python Scripts** above.

When adding an installer, **always ask the user** which profile it belongs to. Then vendor the script, add a row to `.installers/README.md`, add the entry to `installers.toml`, and update the table in the repository `README.md`. Never add an installer that fetches and pipes a remote script.

The runner is deliberately `run_` and not `run_onchange_`: it must run on every apply so an installer skipped for unmet prerequisites is retried later. It tracks its own work with stamps under `~/.local/state/chezmoi/installers/`, fingerprinted from the vendored script's contents plus the entry's `requires` and `env`.

Unmet prerequisites warn and skip; they never fail the apply. Keep it that way — failing would block `chezmoi apply` on a fresh machine where, for example, `gh auth login` has not run yet.

If an installer would write to a chezmoi-managed file, neutralize it through the entry's `env` rather than by patching the vendored script — a verbatim copy stays diffable against upstream. (Graft appends a `PATH` line to the profile of `$SHELL`, so its entry sets `SHELL=/bin/sh` to redirect that write from the managed `~/.zshrc` to the unmanaged, zsh-ignored `~/.profile`.)

---

## Key Commands Reference

| Command                           | Description                                               |
|-----------------------------------|-----------------------------------------------------------|
| `chezmoi add <file>`              | Add a target file to the source directory                 |
| `chezmoi diff`                    | Show pending changes before applying                      |
| `chezmoi apply`                   | Apply source state to the destination (user only)         |
| `chezmoi status`                  | Short status of out-of-sync files                         |
| `chezmoi verify`                  | Check if destination matches target state                 |
| `chezmoi cat <target-path>`       | Print rendered content of a managed file                  |
| `chezmoi execute-template < file` | Render a template file and print output                   |
| `chezmoi data`                    | Print all available template data                         |
| `chezmoi doctor`                  | Diagnose common configuration problems                    |
| `chezmoi git <args>`              | Run a git command in the source directory                 |
| `chezmoi managed`                 | List all files managed by chezmoi                         |
| `chezmoi unmanaged`               | List unmanaged files in the home directory                |

Full reference: https://www.chezmoi.io/reference/
