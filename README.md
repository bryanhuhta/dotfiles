# Dotfiles

This repository contains dotfiles managed using
[chezmoi](https://www.chezmoi.io/).

## Config

Create `~/.config/chezmoi/chezmoi.toml` with a `[data]` section to configure
machine-specific values:

```toml
[data.git]
    name = "Your Name"
    email = "you@example.com"
```

| Key          | Required | Default     | Description                          |
|--------------|----------|-------------|--------------------------------------|
| `git.name`   | yes      | -           | git username                         |
| `git.email`  | yes      | -           | git email                            |
