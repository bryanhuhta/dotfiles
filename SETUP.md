# New Machine Setup (macOS)

Runbook for bootstrapping a fresh Mac up to the point where `chezmoi apply`
can take over. Steps are ordered — later steps depend on earlier ones.

## 1. Xcode Command Line Tools

Provides `git` and the compilers Homebrew needs.

```sh
xcode-select --install
```

## 2. 1Password

The SSH key for GitHub lives in 1Password, so it must be installed and
unlocked before anything can clone over SSH. It is installed by direct
download here because it is needed before Homebrew exists (a `1password`
cask does exist; the `1password-cli` companion is installed later by the
Brewfile).

1. Download from <https://1password.com/downloads/mac> and install.
2. Sign in to the account(s).
3. Enable the SSH agent: Settings → Developer → **Use the SSH agent**.
4. Optionally enable **Integrate with 1Password CLI** (the `op` cask is
   installed later by the Brewfile).

The dotfiles' `~/.ssh/config` points at the 1Password agent socket, but that
file is not applied yet. For the initial clone, point SSH at the agent
manually:

```sh
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

Verify with `ssh -T git@github.com` (1Password will prompt to authorize).

## 3. Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## 4. chezmoi machine config

Templates require machine-local data before the first apply. Create
`~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    profile = "work"

[data.git]
    name = "Your Name"
    email = "you@example.com"
    signingkey = "ssh-ed25519 AAAA..."
```

`signingkey` is the **public** key of the 1Password SSH key (copy it from the
key's item in 1Password). See `README.md` for the full list of supported
variables.

## 5. oh-my-zsh

`.zshrc` sources oh-my-zsh but nothing installs it on macOS profiles. Install
it now, before `chezmoi apply`, because its installer writes its own `.zshrc`
(the apply in the next step overwrites it with the managed one):

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
```

## 6. Init and apply

```sh
brew install chezmoi
chezmoi init git@github.com:bryanhuhta/dotfiles.git
chezmoi diff
sudo -v
chezmoi apply
```

`apply` runs `brew bundle --global`, which installs everything declared in
`~/.Brewfile` for the active profile (see `dot_Brewfile.tmpl` for the list).

Stay at the keyboard: the `dotnet-sdk` cask installs via a macOS pkg and
asks for the admin password partway through (`sudo -v` primes it, but the
first bundle run is long and the sudo timestamp can expire). If the run
fails partway for any reason, both `chezmoi apply` and `brew bundle` are
idempotent - fix the cause and rerun `chezmoi apply`.

## 7. Post-apply

Apps and state that live outside Homebrew and chezmoi:

- **OrbStack** (docker runtime): installed by the Brewfile. Launch it once so
  `~/.orbstack` exists (`.zprofile` and `~/.ssh/config` reference it).
- **UTC Time** (menu bar UTC clock): App Store only — install from
  <https://apps.apple.com/us/app/utc-time/id1538245904>.
- **Tailscale**: the brew formula ships the daemon and cli. Start the daemon
  and authenticate:

  ```sh
  sudo brew services start tailscale
  tailscale up
  ```

- **nvm + node**: install with the official script (it creates `~/.nvm`,
  which `.zprofile` sources). `PROFILE=/dev/null` is required - without it
  the installer appends lines to the chezmoi-managed `~/.zshrc`, breaking
  `chezmoi verify`. Then install a node and the TypeScript tooling nvim's
  `ts_ls` LSP expects:

  ```sh
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash
  source ~/.zprofile
  nvm install --lts
  npm install -g typescript typescript-language-server
  ```
- **Ghostty font**: the managed config uses "Ubuntu Mono derivative
  Powerline", which nothing installs (Ghostty silently falls back to the
  default font without it):

  ```sh
  curl -fsSL -o ~/Library/Fonts/"Ubuntu Mono derivative Powerline.ttf" \
    "https://github.com/powerline/fonts/raw/master/UbuntuMono/Ubuntu%20Mono%20derivative%20Powerline.ttf"
  ```

- **deployment_tools**: work scripts expect it at `~/grafana/deployment_tools`:

  ```sh
  git clone git@github.com:grafana/deployment_tools.git ~/grafana/deployment_tools
  ```

- **Auth**:
  - `gh auth login`
  - `gcloud auth login`, then `gcloud components install gke-gcloud-auth-plugin`
    (kubectl needs it to authenticate against GKE clusters; it lands in
    the `share/google-cloud-sdk/bin` path that `.zprofile` adds)
  - `claude` (first launch authenticates and creates its Keychain items)
- **Keychain secrets**: recreate the items listed in `README.md`. The
  `gcx-sandbox` token must be added manually:

  ```sh
  security add-generic-password -a "$USER" -s "gcx-sandbox" -U -w
  ```

- **Java versions** (as needed): register the brewed JDKs with jenv, e.g.
  `jenv add /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`.
- **Rust** (as needed): nvim enables `rust_analyzer`, which nothing installs.
  If doing Rust work: install [rustup](https://rustup.rs) (its `~/.cargo/env`
  is already sourced by `.zprofile`), then
  `rustup component add rust-analyzer clippy`.

## 8. Verify

```sh
chezmoi doctor
chezmoi verify
brew bundle check --global
```
