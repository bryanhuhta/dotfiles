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
profile's package list).

1. Download from <https://1password.com/downloads/mac> and install.
2. Sign in to the account(s).
3. Enable the SSH agent: Settings → Developer → **Use the SSH agent**.
4. Optionally enable **Integrate with 1Password CLI** (the `op` cask is
   installed later by the profile's package list).

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

## 4. Clone the repository

Each profile has its own source directory at the top of the repository, so the
repository is cloned first and `sourceDir` is pointed at the right one in the
next step. Clone directly rather than using `chezmoi init`: `init` would clone
into whatever `sourceDir` names, and it rewrites `~/.config/chezmoi/chezmoi.toml`
from a template, discarding any values that template does not emit.

```sh
git clone git@github.com:bryanhuhta/dotfiles.git ~/.local/share/chezmoi
```

## 5. chezmoi machine config

Templates require machine-local data before the first apply. Create
`~/.config/chezmoi/chezmoi.toml`:

```toml
sourceDir = "~/.local/share/chezmoi/work-mac"

[data]
    profile = "work-mac"

[data.git]
    name = "Your Name"
    email = "you@example.com"
    signingkey = "ssh-ed25519 AAAA..."
```

`sourceDir` and `profile` must agree — `personal-mac`/`personal-mac`, or
`work-mac`/`work-mac`. Both are required: nothing applies from the repository
root, and chezmoi's default source directory is the root, so omitting
`sourceDir` fails with an explanatory error.

`signingkey` is the **public** key of the 1Password SSH key (copy it from the
key's item in 1Password). See `README.md` for the full list of supported
variables.

## 6. oh-my-zsh

`.zshrc` sources oh-my-zsh but nothing installs it on macOS profiles. Install
it now, before `chezmoi apply`, because its installer writes its own `.zshrc`
(the apply in the next step overwrites it with the managed one):

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
```

## 7. Apply

```sh
brew install chezmoi
chezmoi diff
sudo -v
chezmoi apply
```

`apply` runs `brew bundle`, which installs everything declared in the profile's
`.chezmoidata/packages.toml` (e.g. `work-mac/.chezmoidata/packages.toml`). The
package list is rendered into the install script, so there is no `~/.Brewfile`
on disk.

The bundle run passes `--no-upgrade`, so it only installs what is missing and
leaves already-installed packages at their current versions. Upgrading is a
separate, deliberate `brew upgrade`.

Stay at the keyboard: the `dotnet-sdk` cask installs via a macOS pkg and
asks for the admin password partway through (`sudo -v` primes it, but the
first bundle run is long and the sudo timestamp can expire). If the run
fails partway for any reason, both `chezmoi apply` and `brew bundle` are
idempotent - fix the cause and rerun `chezmoi apply`.

## 8. Post-apply

Apps and state that live outside Homebrew and chezmoi:

- **OrbStack** (docker runtime): installed by the package list. Launch it once so
  `~/.orbstack` exists (`.zprofile` and `~/.ssh/config` reference it).
- **UTC Time** (menu bar UTC clock): App Store only — install from
  <https://apps.apple.com/us/app/utc-time/id1538245904>.
- **Tailscale**: the brew formula ships the daemon and cli. Start the daemon
  and authenticate:

  ```sh
  sudo brew services start tailscale
  tailscale up
  ```

- **nvm + node**: both are managed by chezmoi (`.chezmoiexternal.toml` checks
  out the pinned nvm release, `.chezmoiscripts/run_onchange_after_install-node.sh`
  installs the pinned node and enables Corepack), so nothing to do by hand.
  The TypeScript tooling nvim's `ts_ls` LSP expects is not managed:

  ```sh
  source ~/.zprofile
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
- **Graft** (`work-mac`): installed by the vendored installer in
  `work-mac/.installers/`, but only once `gh auth login` has run — it downloads
  its release artifacts with `gh`. Until then every apply skips it with a
  warning naming the unmet prerequisite. After authenticating, run
  `chezmoi apply` again and it installs. See "Installer scripts" in
  `README.md`.
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

## 9. Verify

```sh
chezmoi doctor
chezmoi verify
```

`chezmoi doctor` only checks that `sourceDir` exists, not that it is the right
one — confirm with `chezmoi data | jq -r '.chezmoi.sourceDir, .profile'` that
both name the intended profile.
