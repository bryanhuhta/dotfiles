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
| `profile`         | no       | `personal`   | dotfile profile                                                |
| `git.name`        | yes      | -            | git username                                                   |
| `git.email`       | yes      | -            | git email                                                      |
| `git.signingkey`  | no       | -            | SSH public key string for commit signing; enables signing when set |
