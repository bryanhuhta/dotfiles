# Dotfiles

This repository contains dotfiles managed using
[chezmoi](https://www.chezmoi.io/).

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
| `profile`         | no       | `personal`   | dotfile profile: `personal`, `work`, or `personal-bazzite`     |
| `git.name`        | yes      | -            | git username                                                   |
| `git.email`       | yes      | -            | git email                                                      |
| `git.signingkey`  | no       | -            | SSH public key string for commit signing; enables signing when set |

## Bazzite

First-time setup only: after the initial `chezmoi apply` installs zsh, do **not** change the system login shell — on Bazzite this can break graphical login. Instead, point your terminal emulator at zsh (ghostty: `command = /home/linuxbrew/.linuxbrew/bin/zsh`; Ptyxis/Konsole: profile → "Use Custom Command").
