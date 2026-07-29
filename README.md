# Dotfiles

This repository contains dotfiles managed using
[chezmoi](https://www.chezmoi.io/).

Setting up a new machine? Follow the runbook in [SETUP.md](SETUP.md).

## Config

Create `~/.config/chezmoi/chezmoi.toml` with a `[data]` section to configure
machine-specific values:

```toml
[data]
    profile = "work"

[data.git]
    name = "Your Name"
    email = "you@example.com"
```

| Key               | Required | Default      | Description                                                    |
|-------------------|----------|--------------|----------------------------------------------------------------|
| `profile`         | yes      | -            | dotfile profile: `personal`, `work`, or `personal-bazzite`; templates fail to render if unset |
| `git.name`        | yes      | -            | git username                                                   |
| `git.email`       | yes      | -            | git email                                                      |
| `git.signingkey`  | no       | -            | SSH public key string for commit signing; enables signing when set |

## MarkEdit preview extension

The [MarkEdit-preview](https://github.com/MarkEdit-app/MarkEdit-preview)
extension is managed by chezmoi on the `work` profile (MarkEdit itself is
installed by the Brewfile there):

- **Version** is pinned in `.chezmoidata.toml` (`markeditPreview.version`).
  To upgrade, pick a tag from the
  [releases](https://github.com/MarkEdit-app/MarkEdit-preview/tags), bump the
  value, and run `chezmoi apply` — `.chezmoiexternal.toml` embeds the version
  in the download URL, so changing it re-downloads the script.
- **Settings** live under the `extension.markeditPreview` node in MarkEdit's
  managed `settings.json`
  (`~/Library/Containers/app.cyan.markedit/Data/Documents/settings.json`).
  The extension's self-update check is set to `never` since chezmoi owns the
  version.

Restart MarkEdit after applying for changes to take effect.

## Keychain secrets

Secrets are never stored in this repository. Scripts read them from the
macOS Keychain at runtime. This table is the authoritative list — when
adding a script that reads a new Keychain item, add it here.

| Keychain item             | Contents                                          | Used by                                     |
|---------------------------|---------------------------------------------------|---------------------------------------------|
| `Claude Code`             | Claude Code credential (managed by Claude Code)   | `sandbox` — passed as `ANTHROPIC_API_KEY`   |
| `Claude Code-credentials` | MCP OAuth tokens (managed by Claude Code)         | `sandbox` — passed as `CLAUDE_CREDENTIALS`  |
| `gcx-sandbox`             | Grafana service-account token (`glsa_...`)        | `sandbox` — passed as `GRAFANA_TOKEN`       |

The `sandbox` script also forwards a GitHub token, but that is managed by
the `gh` CLI (rotate with `gh auth login`), not the Keychain.

### Rotating `Claude Code`

This item is created and updated by Claude Code itself. Re-authenticate to
write a fresh credential:

```sh
claude auth login
```

Revoke the old credential from the Anthropic console (API keys) or your
claude.ai account settings.

### Rotating `Claude Code-credentials`

This item holds OAuth tokens for plugin MCP servers (currently Slack) and
is created and updated by Claude Code itself. To refresh, reconnect the
server on the host: run `/mcp` inside Claude Code and re-authenticate the
Slack server. Revoke old grants from the Slack workspace's app settings.

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
