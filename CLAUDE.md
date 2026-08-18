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

There are four profiles: `personal-mac`, `work-mac`, `personal-bazzite`, and `personal-fedora`. Profile is set in the machine-local config, alongside a `sourceDir` that selects which source directory that machine applies from.

### Per-profile source directories (the Mac profiles)

`personal-mac/` and `work-mac/` are self-contained chezmoi source directories at the top of the repository. The machine-local `chezmoi.toml` points `sourceDir` at one of them, so chezmoi never sees the other profiles' files at all.

Inside a profile directory:

- There are **no `.profile` conditionals**. The directory is the condition. A file that needs to differ per profile simply differs between the two directories, and a file only one profile wants exists only in that directory.
- It owns its own `.chezmoiignore`, `.chezmoidata.toml`, `.chezmoidata/`, `.chezmoiexternal.toml`, and `.chezmoiscripts/`. The root copies of those files do not apply.
- Templating is reserved for machine data (`.git.name`, `.git.email`, `hasKey .git "signingkey"`). If a file has no template actions left after de-templating, drop its `.tmpl` suffix.
- Repository-root assets (`claude-home/`, `zed_settings.json`, the Docker build contexts) live one level up. Reach them with `{{ .chezmoi.sourceDir | dir }}` in a template and `$(dirname $(chezmoi source-path))` in a script — a bare `.chezmoi.sourceDir` resolves inside the profile directory and silently produces a dangling symlink or a missing build context.
- Scripts belong in `.chezmoiscripts/`, not at the top level, so they run without also being written into `$HOME`.

When changing something that both Macs share, make the edit in both directories. There is deliberately no shared layer between them.

### The repository root (the Linux profiles)

`personal-bazzite` and `personal-fedora` still apply from the repository root and set no `sourceDir`, so the root tree keeps using the `{{ if eq .profile ... }}` gating described below. Root `.chezmoiignore` fails with an explanatory error for any other profile value, so a Mac machine with a stale or missing `sourceDir` stops instead of rendering a half-empty tree.

Use separate `if` blocks rather than `if/else` so each profile's section is independently readable:

```
{{- if eq .profile "personal-fedora" }}
# personal-fedora-only config
{{- end }}

{{- if eq .profile "personal-bazzite" }}
# personal-bazzite-only config
{{- end }}
```

**Never treat an unset, empty, or unrecognised profile as a valid case.** It means `chezmoi.toml` is missing or misconfigured on this machine — an error, not another profile — and setup must fail immediately rather than quietly rendering as if it were some other profile. Root `.chezmoiignore` enforces this with a whitelist, not an emptiness check (`not .profile` is false for any non-empty string, so a typo or a stale value would sail straight through):

```
{{- $profile := dig "profile" "" . -}}
{{- if not (has $profile (list "personal-bazzite" "personal-fedora")) }}
{{ fail (printf "profile %q cannot be applied from this source directory — ..." $profile) }}
{{- end }}
```

Because `.chezmoiignore` is read on every chezmoi command, this guard means no other template in the root tree needs to (and none should) special-case a bad profile — by the time any other template renders, `.profile` is guaranteed to be one of the two Linux profiles. If you see `eq .profile ""` anywhere, it's leftover from before this guard existed and should be deleted, not treated as a legitimate branch.

**Never use a bare `else` (or catch-all `else if`) to fall back to a "default" case.** Write one explicit `if` per profile that should get a given piece of config. A profile that matches none of them should render nothing for that block — not silently inherit some other profile's behavior. Implicit defaults are exactly how machine-specific values (a macOS-only path, a brew-only command) leak onto profiles that were never meant to have them:

```
# Bad — a new profile silently inherits the bazzite package manager with no warning:
{{ if eq .profile "personal-fedora" -}}
sudo dnf install -y $packages
{{- else -}}
brew bundle install --global
{{- end }}

# Good — every profile that gets a branch is named explicitly; anything else gets none:
{{ if eq .profile "personal-fedora" -}}
sudo dnf install -y $packages
{{- end }}
{{ if eq .profile "personal-bazzite" -}}
brew bundle install --global
{{- end }}
```

This applies to `.chezmoiignore` blocks and shell script branches (e.g. `run_onchange_install-packages.sh.tmpl`'s package manager selection) just as much as inline template conditionals. When adding a new profile, its config gaps should show up as *missing* config (or a script that visibly no-ops), never as another profile's config applied by accident.

**Never gate an entire file's existence by wrapping all of its content in one `{{ if }}`.** If a file is only relevant to one (or a few) profiles, use `.chezmoiignore` to exclude its target on every other profile instead. A whole-file `{{ if }}` still creates the file — empty, but present and marked as managed — everywhere the condition is false; `.chezmoiignore` is what actually keeps it off other profiles:

```
# Bad — renders (and "runs", for a script) as an empty no-op on every other profile:
{{ if eq .profile "personal-bazzite" -}}
#!/bin/bash
brew install zsh
...
{{- end }}

# Good — the file only needs to exist for one profile, so gate its existence in .chezmoiignore,
# and drop the .tmpl suffix from the file entirely if nothing inside it needs to be templated:
#!/bin/bash
brew install zsh
...
```
```
# .chezmoiignore
{{- if eq .profile "personal-fedora" }}
install-zsh.sh
{{- end }}
```

**Exception: `.chezmoiexternal.toml` and `.chezmoidata*` are not covered by `.chezmoiignore`.** For ordinary files and scripts, chezmoi checks the ignore list *before* evaluating a template's contents, so an ignored template never runs. Those two are different: they are executed during the source-directory walk, before `.chezmoiignore` is read. If one of them calls something side-effecting or environment-dependent (`onepasswordRead`, `output`, `exec` — anything that shells out or depends on machine state), it needs an in-template `{{ if }}` guard around that call, because no ignore entry can stop it from running. Note that `chezmoi cat` and `chezmoi execute-template` bypass ignores entirely, so neither is evidence about what `apply` would do.

**When to split vs combine:** Use a single file with `if` blocks when profile differences are small. Use separate files per profile when differences are large enough that a single file becomes hard to follow.

Profiles are intentionally decoupled from hostnames or other machine identifiers. Never gate behavior on `.chezmoi.hostname` or similar — the profile variable exists precisely so config stays valid when hardware changes.

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

# Conditional block (root tree only — profile directories have no conditionals)
{{- if eq .profile "personal-fedora" }}
export FEDORA_ONLY=1
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
