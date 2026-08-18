# Known Bugs and Issues

Findings from an audit of this repository against chezmoi v2.72.0 on 2026-08-17. **Nothing was fixed at the time of the audit** — see the status update below for what the restructure has since closed. This file is a record so the issues are not rediscovered from scratch, and so the restructure work can be evaluated against a known baseline.

**Status update (personal-mac migration).** The audit above predates the split into per-profile source directories. `work-mac/` and `personal-mac/` now exist, the `personal` and `work` profiles are gone, and the repository root serves only `personal-bazzite` and `personal-fedora`. That work closed the following entries: **#1**, **#2** (root `.chezmoiignore` now whitelists the two Linux profiles and fails with an explanatory message for anything else), **#3** (the macOS-only `private_Library/` tree is gone from the root), **#4** (neither Mac gets `~/.dnf-packages`), **#6** (the header-only `agent.toml` is no longer rendered on Linux), **#8** (the managed Ghostty target on both Macs is now named `config`), **#9** (`run_onchange_install-nvm.sh` deleted), **#17**, and **#18**. Partially closed: **#13** (both Macs run their scripts from `.chezmoiscripts/`; the Linux profiles still materialise theirs in `$HOME`) and **#14** (`dot_zshrc` and the Mac Ghostty configs lost their pointless `.tmpl`; root `dot_zshenv.tmpl` and `private_dot_config/private_ghostty/config.tmpl` still carry it). Still open and unchanged: **#5**, **#7**, **#10**, **#11**, **#12** (the `~/.local/bin` split was carried over to `personal-mac` as-is, deliberately), **#15**, and **#16**.

Each entry states what was verified and how. Entries marked *verified* were reproduced with a real command against this machine or against a rendered profile; entries marked *observed* come from reading the source or the repo without a live reproduction.

Profiles are rendered for inspection without applying by pointing chezmoi at a throwaway config:

```sh
cat > /tmp/cfg-personal-fedora.toml <<'EOF'
[data]
    profile = "personal-fedora"
[data.git]
    name = "Test User"
    email = "test@example.com"
    signingkey = "ssh-ed25519 AAAATEST"
EOF
chezmoi --config=/tmp/cfg-personal-fedora.toml managed
chezmoi --config=/tmp/cfg-personal-fedora.toml cat ~/.ssh/config
```

---

## Part 1: Repository bugs

### 1. An unrecognised `profile` value renders as a silent fifth profile — HIGH

*Verified.* This machine's `~/.config/chezmoi/chezmoi.toml` reads `profile = "work-mac"`. No template or `.chezmoiignore` block in the repo matches that string; the repo knows only `personal`, `work`, `personal-bazzite`, and `personal-fedora`. Every profile-specific block is therefore omitted, and `chezmoi apply` would:

| Target | Result |
|---|---|
| `~/.gitconfig` | `[gpg "ssh"]` renders with no `program` line, so SSH commit signing stops routing through 1Password's `op-ssh-sign` |
| `~/.ssh/config` | `Host *` renders with no `IdentityAgent`, so the 1Password SSH agent is not wired up |
| `~/.config/1Password/ssh/agent.toml` | renders with no `[[ssh-keys]]` stanza |
| `~/.Brewfile` | drops to the 8 shared formulae; every work cask and formula disappears |
| `~/.dnf-packages`, `~/.config/ghostty/config` | both created on macOS |

Repro: `chezmoi data | jq -r .profile` returns `work-mac`; `grep -rn 'work-mac' --include='*.tmpl' . .chezmoiignore` returns nothing.

### 2. The `.chezmoiignore` profile guard does not catch invalid profiles — HIGH

*Verified.* The guard is `{{ if not .profile }}{{ fail ... }}{{ end }}`. `not` is false for any non-empty string, so it only catches a missing or empty value. Any typo or stale value passes straight through and produces bug #1. There is no whitelist check anywhere.

### 3. `personal-bazzite` creates three empty macOS `Library` directories on Linux — MEDIUM

*Verified.* `chezmoi --config=/tmp/cfg-personal-bazzite.toml managed` lists `Library`, `Library/Application Support`, and `Library/Containers`. The `.chezmoiignore` block for that profile excludes the leaf paths (`Library/Application Support/com.mitchellh.ghostty/**` and `Library/Containers/app.cyan.markedit/**`) but not the parent directories, so the directories are still managed and created empty.

### 4. All four profiles receive `~/.dnf-packages`, including the two Macs — MEDIUM

*Verified.* `chezmoi --config=/tmp/cfg-personal.toml managed | grep dnf-packages` matches, and `chezmoi --config=/tmp/cfg-personal.toml cat ~/.dnf-packages` renders a 477-byte comment-only stub. `dot_dnf-packages.tmpl` gates only its *body* on `eq .profile "personal-fedora"`; the file itself is never excluded on other profiles. Same class of problem for `~/.Brewfile` on `personal-bazzite`, which is correct there, and on `personal-fedora`, which excludes it explicitly.

### 5. `personal-fedora` gets the OrbStack `Include` in `~/.ssh/config` — MEDIUM

*Verified.* `chezmoi --config=/tmp/cfg-personal-fedora.toml cat ~/.ssh/config` emits `Include ~/.orbstack/ssh/config` and its two-line comment. OrbStack is macOS-only. The line is inert, but it is macOS configuration on a Linux box and the comment claims it is "silently ignored on machines without OrbStack", which papers over the leak rather than fixing it.

### 6. `personal-fedora` and `personal-bazzite` get a 1Password agent config with no keys — MEDIUM

*Verified.* `chezmoi --config=/tmp/cfg-personal-fedora.toml cat ~/.config/1Password/ssh/agent.toml | grep -c '^\[\[ssh-keys\]\]'` returns **0**, versus **1** for `personal`. `private_agent.toml.tmpl` has branches only for `personal` and `work`, so both Linux profiles receive the ~30-line comment header and nothing else. The header also documents the macOS `~/Library/Group Containers/...` socket path, which is wrong on Linux.

### 7. Two macOS-only scripts install on `personal-bazzite` — MEDIUM

*Verified.* `chezmoi --config=/tmp/cfg-personal-bazzite.toml managed` lists `.local/bin/wakeup` and `.local/bin/sandbox`. `executable_wakeup:119` calls `caffeinate`, which is macOS-only. `executable_sandbox:55` and `:76` call `security find-generic-password`, the macOS Keychain CLI. Neither exists on Linux; both scripts fail at runtime.

### 8. The macOS Ghostty config has never taken effect — MEDIUM

*Verified.* The managed target is `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`, but Ghostty reads a file named `config` with no extension. On this machine that directory contains exactly one file, `config.ghostty` (127 bytes), so the font settings are not being applied. Separately, `~/.config/ghostty` (which Ghostty *does* read on macOS) is excluded on both Mac profiles by `.chezmoiignore`, and `~/.config/ghostty/` does not exist here. Net effect: neither Mac has a Ghostty config that Ghostty reads.

### 9. `run_onchange_install-nvm.sh` is dead code that double-installs nvm — MEDIUM

*Observed.* nvm is installed by the `[".nvm"]` entry in `.chezmoiexternal.toml`, pinned to `nvm.version` in `.chezmoidata.toml`. The script installs it a second time and hardcodes `v0.40.6` inline, making it a second source of truth that will silently diverge when `.chezmoidata.toml` is bumped. It is excluded on `personal`, `personal-bazzite`, and `personal-fedora`, so it runs only on `work`.

### 10. `executable_sso` hardcodes an absolute home directory — LOW

*Observed.* The script passes `--kubeconfig="/Users/work/.kube/config"`. This breaks for any other username and on any non-macOS path layout. Should be `$HOME/.kube/config`.

### 11. The Fedora package list is missing two hard dependencies — MEDIUM

*Observed.* `dot_dnf-packages.tmpl` does not list `jq`, which `dot_docker/modify_private_config.json.tmpl` invokes unconditionally at apply time, nor `chezmoi` itself, which `.zshrc` aliases as `z`. On a fresh Fedora box the docker `modify_` script fails.

### 12. `.chezmoiignore` gating of `~/.local/bin` scripts is internally inconsistent — LOW

*Observed.* The current assignment encodes taste rather than capability, and contradicts itself: `gifify`, `jpegify`, and `slackify` are work-only while `movtomp4`, which uses the same `utility` container, is available everywhere; `ts2date` is work-only despite node being installed on `personal` too; and `scan` the script is work-only while `scan/`, its Docker build context, is excluded on every profile.

### 13. Five `run_` scripts install as visible files in `$HOME` — LOW

*Observed.* `install-packages.sh`, `install-node.sh`, `install-nvm.sh`, `install-zsh.sh`, and `swap-caps-escape.sh` all land in the home directory as real files, which is why `.chezmoiignore` carries bare filenames like `install-zsh.sh` to subtract them per profile. `.chezmoiscripts/` exists precisely to run scripts without creating a target entry and is not used.

### 14. Three files carry a `.tmpl` suffix with zero template actions — LOW

*Observed.* `dot_zshenv.tmpl`, `private_dot_config/private_ghostty/config.tmpl`, and `private_Library/.../config.ghostty.tmpl` contain no `{{ }}` at all. The suffix on the last one was added by commit `3c14889`, which otherwise correctly removed a stray empty `font-family = ""` line that preceded the real one.

### 15. Neovim registers two language servers that are never installed — LOW

*Observed.* `lua/lsp.lua` enables `rust_analyzer` and `typescript-language-server`, neither of which is in any package list. `SETUP.md` documents installing them by hand as optional post-apply steps. They are silent no-ops on nvim 0.12 (`vim.lsp.enable()` for a missing binary logs to the LSP log and does nothing), so this is a documentation and expectation problem, not a runtime failure.

### 16. `README.md` and `SETUP.md` recommend `chezmoi update` — LOW

*Observed.* `chezmoi update` pulls and applies in a single step. `CLAUDE.md` mandates reviewing with `chezmoi diff` before applying, which `update` makes impossible. The safe equivalent is `chezmoi cd && git pull && exit`, then `chezmoi diff`, then `chezmoi apply`.

### 17. `README.md`'s profile table is incomplete — LOW

*Observed.* The table lists `personal`, `work`, and `personal-bazzite`. `personal-fedora` exists in `.chezmoiignore`, `dot_dnf-packages.tmpl`, `dot_gitconfig.tmpl`, `private_dot_ssh/config.tmpl`, and `dot_docker/modify_private_config.json.tmpl`, but is not documented.

### 18. `CLAUDE.md` states an incorrect rule about `.chezmoiignore` ordering — MEDIUM

*Verified in source.* `CLAUDE.md` says `.chezmoiignore` "filters the target only *after* the whole template has already been rendered", and uses that to justify an in-template `{{ if }}` guard around `onepasswordRead` in `private_dot_ssh/wrightauto.pub.tmpl`. For ordinary files and scripts this is false: the `s.Ignore(targetRelPath)` check at `internal/chezmoi/sourcestate.go:1143` runs *before* contents are evaluated, so an ignored template is never executed. The claim is true only for `.chezmoiexternal*` and `.chezmoidata*`, whose templates are executed during the source walk before `.chezmoiignore` is read. The original "verified empirically" note most likely observed `chezmoi cat` or `chezmoi execute-template`, both of which bypass ignores entirely.

---

## Part 2: chezmoi behaviours that cost us time

Not bugs in this repo. These are upstream behaviours, all verified against chezmoi v2.72.0, that are silent, surprising, or destructive. They constrain what any restructure can do.

### A. `.chezmoiroot` is never templated, and fails silently

`internal/cmd/config.go:1714` reads the file with `ReadFile` + `bytes.TrimSpace` and passes it to `NewUntrustedRelPath`. There is no template execution in `getSourceDirAbsPath` and no `.chezmoiroot.tmpl`. A `.chezmoiroot` containing `{{ .profile }}` resolves to a directory literally named `{{ .profile }}`, and `chezmoi managed` then exits 0 printing nothing.

### B. Symlinking a source *subdirectory* produces an empty managed directory, silently

`internal/chezmoi/system.go:202`, `walkSourceDirHelper`, decides whether to recurse from the lstat `FileInfo`. A symlinked directory reports `!fileInfo.IsDir()` and recursion stops. chezmoi registers the entry as a managed but empty directory, applies an empty directory to the target, and `chezmoi verify` still passes. Under an `exact_` parent it would delete the real contents.

### C. A dangling *source* symlink aborts everything; a dangling *target* symlink is harmless

With a source symlink whose destination is deleted, `chezmoi managed`, `status`, `diff`, **and** `apply` all exit 1 with a `stat` error, and unrelated pending changes go unapplied. A `symlink_*.tmpl` whose body points at a missing path applies cleanly at rc=0 and leaves a dangling link in `$HOME` while chezmoi stays healthy. This asymmetry is why target symlinks are usable and source symlinks are not.

### D. `chezmoi re-add` silently converts a source symlink into a regular file

After editing a target whose source entry is a symlink, `chezmoi re-add` exits 0 with no output and replaces the symlink with a regular file. Any sharing arrangement built on source symlinks un-shares itself one file at a time with nothing to say so.

### E. Replacing a populated directory with a symlink deletes it, silently

Applying a `symlink_` entry over an existing populated directory removes the directory and everything unmanaged inside it. `chezmoi apply` exits 0 with no prompt. `chezmoi diff` beforehand shows only `deleted file mode 40755` and names no files.

### F. `chezmoi init` destroys config data the template does not emit

`chezmoi init` regenerates `~/.config/chezmoi/chezmoi.toml` from `.chezmoi.$FORMAT.tmpl`. Anything the template omits is gone. A template emitting only `sourceDir` and `profile`, run against a config containing a populated `[data.git]`, wiped `name`, `email`, and `signingkey` at rc=0. `promptStringOnce` preserves existing values byte-for-byte and non-interactively.

### G. A missing template data key aborts the *entire* apply

chezmoi runs templates with `missingkey=error`. With `git.signingkey` absent, `chezmoi status` and `chezmoi apply` both exit 1 on `.ssh/allowed_signers` and **nothing at all** is applied, including unrelated files. This is why the `hasKey .git "signingkey"` guard in `.chezmoiignore` matters.

### H. `chezmoi doctor` does not catch a wrong-but-existing `sourceDir`

Doctor errors only on a *nonexistent* source directory. Pointed at an existing directory that is not the intended one, it reports `ok source-dir` (or a `warning` about a dirty git tree) and prints no errors, while `chezmoi managed` exits 0 with empty output. Neither command is a valid way to verify a machine is configured correctly.

### I. `--source` / `--destination` / `--config` do **not** sandbox `run_` scripts

These flags redirect the source state and target, but a script's own commands run against the real machine. During this audit a package-install test script with a hardcoded `/opt/homebrew/bin/brew` executed for real from inside a scratch sandbox and installed `pipx`, `ncurses`, and `zsh` on this Mac. When testing package scripts, stub the package manager by absolute path, or use `apply --dry-run`, which does not execute scripts.

### J. An unfetched external blocks unrelated files; a cached one does not

An external that has never been downloaded makes `status`, `diff`, and `apply` all fail with the network error and blocks unrelated targets. A cached external within its `refreshPeriod` is fully offline-safe: with the server unreachable, `status`, `diff`, and `apply` all returned rc=0. Only `--refresh-externals` forces a re-fetch.

### K. `run_once_` and `run_onchange_` are keyed differently

`run_once_` is keyed by the SHA256 of the script's rendered contents (`internal/chezmoi/targetstateentry.go:433`), so it is path-independent and survives a move. `run_onchange_` is keyed by the target absolute path (`:441`), so relocating a script makes it fire once more. Persistent state lives in `chezmoistate.boltdb` beside the config file, not in the source directory, so it survives a source-directory change.

### L. `git-repo` externals cannot map a subdirectory

There is no subdirectory selection and no `stripComponents` for `type = "git-repo"`. It clones the whole repository into the target, `.git` included, with source-state prefixes undecoded.
