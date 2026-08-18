# Dotfiles

This repository contains dotfiles managed using
[chezmoi](https://www.chezmoi.io/).

Setting up a new machine? Follow the runbook in [SETUP.md](SETUP.md).

## Layout

The Mac profiles each have their own self-contained chezmoi source directory at
the top of this repository; the Linux profiles still share the repository root.

| Profile            | Source directory        |
|--------------------|-------------------------|
| `personal-mac`     | `personal-mac/`         |
| `work-mac`         | `work-mac/`             |
| `personal-bazzite` | repository root         |
| `personal-fedora`  | repository root         |

A profile directory holds its own `.chezmoiignore`, `.chezmoidata/`,
`.chezmoiexternal.toml`, and `.chezmoiscripts/`, and contains no profile
conditionals — the directory *is* the condition. Files shared by every profile
(`claude-home/`, `zed_settings.json`, the Docker build contexts) stay at the
repository root and are reached from a profile directory with
`{{ .chezmoi.sourceDir | dir }}` in templates, or
`$(dirname $(chezmoi source-path))` in scripts.

The repository root refuses to apply for a Mac profile: `.chezmoiignore` fails
with an explanatory error for any profile other than `personal-bazzite` and
`personal-fedora`.

## Config

Create `~/.config/chezmoi/chezmoi.toml` to configure machine-specific values.
On a Mac, `sourceDir` selects the profile directory:

```toml
sourceDir = "~/.local/share/chezmoi/work-mac"

[data]
    profile = "work-mac"

[data.git]
    name = "Your Name"
    email = "you@example.com"
```

| Key               | Required | Default      | Description                                                    |
|-------------------|----------|--------------|----------------------------------------------------------------|
| `sourceDir`       | Macs only| repo root    | profile source directory; must match `profile`                 |
| `profile`         | yes      | -            | dotfile profile: `personal-mac`, `work-mac`, `personal-bazzite`, or `personal-fedora` |
| `git.name`        | yes      | -            | git username                                                   |
| `git.email`       | yes      | -            | git email                                                      |
| `git.signingkey`  | no       | -            | SSH public key string for commit signing; enables signing when set |

## MarkEdit preview extension

The [MarkEdit-preview](https://github.com/MarkEdit-app/MarkEdit-preview)
extension is managed by chezmoi on the `personal-mac` and `work-mac` profiles
(MarkEdit itself is installed by the package list there):

- **Version** is pinned in the profile's `.chezmoidata.toml`
  (`markeditPreview.version`).
  To upgrade, pick a tag from the
  [releases](https://github.com/MarkEdit-app/MarkEdit-preview/tags), bump the
  value, and run `chezmoi apply` — the profile's `.chezmoiexternal.toml` embeds
  the version in the download URL, so changing it re-downloads the script.
- **Settings** live under the `extension.markeditPreview` node in MarkEdit's
  managed `settings.json`
  (`~/Library/Containers/app.cyan.markedit/Data/Documents/settings.json`).
  The extension's self-update check is set to `never` since chezmoi owns the
  version.

Restart MarkEdit after applying for changes to take effect.

## Node.js (nvm + yarn)

Node tooling is managed by chezmoi on the `personal-mac` and `work-mac`
profiles (it lives outside the package list because nvm is unsupported under
Homebrew and brew's `yarn` would drag in brew's own `node`):

- **nvm** is installed as an archive checkout of the pinned release
  (`nvm.version` in the profile's `.chezmoidata.toml`) via its
  `.chezmoiexternal.toml` — not
  with nvm's `install.sh`, which would edit the chezmoi-managed shell
  profile. To upgrade, pick a tag from the
  [releases](https://github.com/nvm-sh/nvm/releases), bump the value, and
  run `chezmoi apply`.
- **node** is installed by `.chezmoiscripts/run_onchange_after_install-node.sh`,
  pinned as `node.version` in the profile's `.chezmoidata.toml`. Bump the value and run
  `chezmoi apply` to install the new version and make it the nvm default
  (old versions are kept; remove them with `nvm uninstall <version>`).
- **yarn** comes from Corepack (bundled with node), enabled by the same
  script — there is no separate yarn install.

## Keychain secrets

Secrets are never stored in this repository. Scripts read them from the
macOS Keychain at runtime. This table is the authoritative list — when
adding a script that reads a new Keychain item, add it here.

| Keychain item             | Contents                                              | Used by                                     |
|---------------------------|-------------------------------------------------------|---------------------------------------------|
| `Claude Code-credentials` | Claude OAuth + MCP OAuth tokens (managed by Claude Code) | `sandbox` — passed as `CLAUDE_CREDENTIALS`  |
| `gcx-sandbox`             | Grafana service-account token (`glsa_...`)            | `sandbox` — passed as `GRAFANA_TOKEN`       |

The `sandbox` script also forwards a GitHub token, but that is managed by
the `gh` CLI (rotate with `gh auth login`), not the Keychain.

### Rotating `Claude Code-credentials`

This item holds the Claude Code OAuth tokens (enterprise login) plus OAuth
tokens for plugin MCP servers (currently Slack), and is created and updated
by Claude Code itself. To refresh the Claude login, run `claude` and
re-authenticate (`/login`); revoke old sessions from your claude.ai account
settings. To refresh MCP tokens, run `/mcp` inside Claude Code and
re-authenticate the Slack server; revoke old grants from the Slack
workspace's app settings.

### Rotating `gcx-sandbox`

1. In the Grafana instance, create a new token for the service account
   (Administration → Users and access → Service accounts), then revoke the
   old token.
2. Update the Keychain item — the `-w` flag with no value prompts for the
   token interactively so it stays out of shell history:

   ```sh
   security add-generic-password -a "$USER" -s "gcx-sandbox" -U -w
   ```

## Bazzite

First-time setup only: after the initial `chezmoi apply` installs zsh, do **not** change the system login shell — on Bazzite this can break graphical login. Instead, point your terminal emulator at zsh (ghostty: `command = /home/linuxbrew/.linuxbrew/bin/zsh`; Ptyxis/Konsole: profile → "Use Custom Command").
