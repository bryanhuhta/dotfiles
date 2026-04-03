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

Dotfiles are written to support multiple profiles (e.g. `work`, `personal`). Profile is set in the machine-local config and controls which sections of templates are rendered.

Use separate `if` blocks rather than `if/else` so each profile's section is independently readable:

```
{{- if or (eq .profile "personal") (eq .profile "") }}
# personal-only config
{{- end }}

{{- if eq .profile "work" }}
# work-only config
{{- end }}
```

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

# Conditional block
{{- if eq .profile "work" }}
export WORK_ONLY=1
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
