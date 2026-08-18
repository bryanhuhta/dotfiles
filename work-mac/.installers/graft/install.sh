#!/bin/sh
set -e

GRAFT_VERSION_URL="${GRAFT_VERSION_URL:-https://grafana.github.io/plugin-graft/version.json}"
MIN_NODE_MAJOR=20

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      echo "Windows support is coming soon. See https://github.com/grafana/plugin-graft for updates." >&2
      exit 1
      ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64)  echo "x64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

check_requirements() {
  DOWNLOAD_CMD=""
  if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl"
  elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget"
  else
    echo "Error: Neither curl nor wget found." >&2
    echo "Please install curl or wget and try again." >&2
    exit 1
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    echo "Error: unzip not found." >&2
    echo "Please install unzip and try again." >&2
    exit 1
  fi
}

prompt_yn() {
  prompt_msg="$1"
  if [ "${GRAFT_NONINTERACTIVE:-}" = "1" ]; then
    echo "$prompt_msg [auto-yes]"
    return 0
  fi
  echo "" >&2
  echo "  -----------------------------------------------" >&2
  echo "" >&2
  if [ -t 0 ]; then
    printf "  %s [Y/n] " "$prompt_msg"
    read -r answer
  elif [ -e /dev/tty ]; then
    printf "  %s [Y/n] " "$prompt_msg"
    read -r answer < /dev/tty
  else
    return 1
  fi
  echo "" >&2
  case "$answer" in
    [nN]*) return 1 ;;
    *) return 0 ;;
  esac
}

detect_linux_pkg_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo ""
  fi
}

sudo_prefix() {
  if [ "$(id -u)" = "0" ]; then
    echo ""
  elif command -v sudo >/dev/null 2>&1; then
    echo "sudo "
  else
    echo ""
  fi
}

install_node_linux() {
  SUDO=$(sudo_prefix)
  PKG_MGR=$(detect_linux_pkg_manager)
  case "$PKG_MGR" in
    apt)
      SETUP_SCRIPT="/tmp/nodesource_setup.sh"
      if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x -o "$SETUP_SCRIPT"
      else
        wget -q -O "$SETUP_SCRIPT" https://deb.nodesource.com/setup_lts.x
      fi
      ${SUDO}sh "$SETUP_SCRIPT"
      ${SUDO}apt-get install -y nodejs
      rm -f "$SETUP_SCRIPT"
      ;;
    dnf)
      ${SUDO}dnf install -y nodejs npm
      ;;
    pacman)
      ${SUDO}pacman -S --noconfirm nodejs npm
      ;;
    *)
      echo "  Error: No supported package manager found for Node.js." >&2
      return 1
      ;;
  esac
}

install_node_macos_direct() {
  TEMP_DIR=$(mktemp -d)

  echo "  Fetching latest Node.js LTS version from nodejs.org..."
  NODE_INDEX_JSON=$(fetch_url "https://nodejs.org/dist/index.json")
  NODE_LTS_VERSION=$(echo "$NODE_INDEX_JSON" | tr '{' '\n' | sed -n '/"lts":"[A-Za-z]/{s/.*"version":"\([^"]*\)".*/\1/p;q;}')

  if [ -z "$NODE_LTS_VERSION" ]; then
    echo "  Error: Could not determine Node.js LTS version." >&2
    rm -rf "$TEMP_DIR"
    return 1
  fi

  NODE_DL_ARCH="$ARCH"
  if [ "$NODE_DL_ARCH" = "x64" ]; then
    NODE_DL_ARCH="x64"
  fi

  NODE_TARBALL="node-${NODE_LTS_VERSION}-darwin-${NODE_DL_ARCH}.tar.gz"
  NODE_URL="https://nodejs.org/dist/${NODE_LTS_VERSION}/${NODE_TARBALL}"

  echo "  Downloading ${NODE_URL}..."
  if [ "$DOWNLOAD_CMD" = "curl" ]; then
    curl -fsSL -o "$TEMP_DIR/$NODE_TARBALL" "$NODE_URL"
  else
    wget -q -O "$TEMP_DIR/$NODE_TARBALL" "$NODE_URL"
  fi

  mkdir -p "$HOME/.local"
  tar -xzf "$TEMP_DIR/$NODE_TARBALL" -C "$HOME/.local" --strip-components=1

  rm -rf "$TEMP_DIR"
  echo "  Node.js ${NODE_LTS_VERSION} installed to ~/.local/bin/node"
}

install_git_macos_direct() {
  echo "  Installing Xcode Command Line Tools (includes Git)..."
  xcode-select --install 2>/dev/null || true
}

install_gh_direct() {
  echo "  Downloading GitHub CLI..."
  GH_INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$GH_INSTALL_DIR"

  GH_DL_ARCH="$ARCH"
  if [ "$GH_DL_ARCH" = "x64" ]; then
    GH_DL_ARCH="amd64"
  fi

  GH_DL_OS="linux"
  GH_DL_EXT="tar.gz"
  if [ "$OS" = "macos" ]; then
    GH_DL_OS="macOS"
    GH_DL_EXT="zip"
  fi

  TEMP_DIR=$(mktemp -d)

  GH_LATEST=$(fetch_url "https://api.github.com/repos/cli/cli/releases/latest" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\([^"]*\)".*/\1/p' | head -1)
  if [ -z "$GH_LATEST" ]; then
    echo "  Error: Could not determine latest GitHub CLI version." >&2
    rm -rf "$TEMP_DIR"
    return 1
  fi

  GH_ARCHIVE="gh_${GH_LATEST}_${GH_DL_OS}_${GH_DL_ARCH}.${GH_DL_EXT}"
  GH_URL="https://github.com/cli/cli/releases/download/v${GH_LATEST}/${GH_ARCHIVE}"

  echo "  Downloading ${GH_URL}..."
  if [ "$DOWNLOAD_CMD" = "curl" ]; then
    curl -fsSL -o "$TEMP_DIR/$GH_ARCHIVE" "$GH_URL"
  else
    wget -q -O "$TEMP_DIR/$GH_ARCHIVE" "$GH_URL"
  fi

  if [ "$GH_DL_EXT" = "zip" ]; then
    unzip -q "$TEMP_DIR/$GH_ARCHIVE" -d "$TEMP_DIR"
  else
    tar -xzf "$TEMP_DIR/$GH_ARCHIVE" -C "$TEMP_DIR"
  fi

  cp "$TEMP_DIR/gh_${GH_LATEST}_${GH_DL_OS}_${GH_DL_ARCH}/bin/gh" "$GH_INSTALL_DIR/gh"
  chmod +x "$GH_INSTALL_DIR/gh"

  rm -rf "$TEMP_DIR"
  echo "  GitHub CLI installed to ${GH_INSTALL_DIR}/gh"
}

# Returns 0 when node is on PATH and major >= MIN_NODE_MAJOR.
node_version_meets_minimum() {
  command -v node >/dev/null 2>&1 || return 1
  _graft_nv=$(node --version 2>/dev/null || echo "")
  [ -z "$_graft_nv" ] && return 1
  _graft_nm=$(echo "$_graft_nv" | sed 's/v\([0-9]*\).*/\1/')
  [ "$_graft_nm" -ge "$MIN_NODE_MAJOR" ] 2>/dev/null
}

# Sources nvm and activates an already-installed Node (default or LTS) without downloading.
activate_nvm_node_on_path() {
  [ "$HAS_NVM" = "1" ] || return 0
  [ -s "$HOME/.nvm/nvm.sh" ] || return 0
  . "$HOME/.nvm/nvm.sh"
  node_version_meets_minimum && return 0
  nvm use default >/dev/null 2>&1
  node_version_meets_minimum && return 0
  nvm use --lts >/dev/null 2>&1
  node_version_meets_minimum && return 0
  return 0
}

scan_dependencies() {
  NEED_NODE=0; NEED_GIT=0; NEED_GH=0
  NODE_OUTDATED=0; NODE_CURRENT_VERSION=""
  MISSING_COUNT=0

  if ! command -v node >/dev/null 2>&1; then
    NEED_NODE=1
    MISSING_COUNT=$((MISSING_COUNT + 1))
  else
    NODE_CURRENT_VERSION=$(node --version 2>/dev/null || echo "")
    if [ -z "$NODE_CURRENT_VERSION" ]; then
      NEED_NODE=1
      MISSING_COUNT=$((MISSING_COUNT + 1))
    else
      NODE_MAJOR=$(echo "$NODE_CURRENT_VERSION" | sed 's/v\([0-9]*\).*/\1/')
      if [ "$NODE_MAJOR" -lt "$MIN_NODE_MAJOR" ] 2>/dev/null; then
        NEED_NODE=1
        NODE_OUTDATED=1
        MISSING_COUNT=$((MISSING_COUNT + 1))
      fi
    fi
  fi
  if ! command -v git >/dev/null 2>&1; then
    NEED_GIT=1
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
  if ! command -v gh >/dev/null 2>&1; then
    NEED_GH=1
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
}

dep_install_method() {
  _tool="$1"
  case "$_tool" in
    node)
      if [ "$HAS_NVM" = "1" ]; then
        echo "via nvm"
      elif [ "$OS" = "macos" ] && [ "$HAS_BREW" = "1" ]; then
        echo "via Homebrew"
      elif [ "$OS" = "macos" ]; then
        echo "from nodejs.org"
      else
        echo "via NodeSource"
      fi
      ;;
    git)
      if [ "$OS" = "macos" ] && [ "$HAS_BREW" = "1" ]; then
        echo "via Homebrew"
      elif [ "$OS" = "macos" ]; then
        echo "via xcode-select"
      else
        PKG_MGR=$(detect_linux_pkg_manager)
        if [ -n "$PKG_MGR" ]; then
          echo "via $PKG_MGR"
        else
          echo "via package manager"
        fi
      fi
      ;;
    gh)
      if [ "$OS" = "macos" ] && [ "$HAS_BREW" = "1" ]; then
        echo "via Homebrew"
      elif [ "$OS" = "macos" ]; then
        echo "from github.com/cli/cli"
      else
        PKG_MGR=$(detect_linux_pkg_manager)
        if [ -n "$PKG_MGR" ]; then
          echo "via $PKG_MGR"
        else
          echo "from github.com/cli/cli"
        fi
      fi
      ;;
  esac
}

show_dependency_summary() {
  echo ""
  echo "  Checking dependencies..."
  echo ""

  if [ "$NEED_NODE" = "1" ] && [ "$NODE_OUTDATED" = "1" ]; then
    echo "  [ ] Node.js LTS    (${NODE_CURRENT_VERSION} found, need v${MIN_NODE_MAJOR}+; will install $(dep_install_method node))"
  elif [ "$NEED_NODE" = "1" ]; then
    echo "  [ ] Node.js LTS    (will install $(dep_install_method node))"
  elif [ -n "$NODE_CURRENT_VERSION" ]; then
    echo "  [x] Node.js        ${NODE_CURRENT_VERSION}"
  else
    echo "  [x] Node.js"
  fi

  if [ "$NEED_GIT" = "1" ]; then
    echo "  [ ] Git             (will install $(dep_install_method git))"
  else
    echo "  [x] Git"
  fi

  if [ "$NEED_GH" = "1" ]; then
    echo "  [ ] GitHub CLI      (will install $(dep_install_method gh))"
  else
    echo "  [x] GitHub CLI"
  fi

  echo ""
  if [ "$MISSING_COUNT" = "1" ]; then
    echo "  Graft needs to install 1 dependency."
  else
    echo "  Graft needs to install $MISSING_COUNT dependencies."
  fi
  echo "  https://github.com/grafana/plugin-graft/blob/main/docs/install-script.md#3-installs-dependencies"
}

install_node() {
  if [ "$HAS_NVM" = "1" ]; then
    echo "  Loading nvm..."
    . "$HOME/.nvm/nvm.sh"
    if node_version_meets_minimum; then
      echo "  Node.js $(node --version) already satisfies v${MIN_NODE_MAJOR}+; skipping nvm install."
      return 0
    fi
    echo "  Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
  elif [ "$OS" = "macos" ] && [ "$HAS_BREW" = "1" ]; then
    echo "  Installing Node.js LTS..."
    brew install node
  elif [ "$OS" = "macos" ]; then
    echo "  Installing Node.js LTS..."
    install_node_macos_direct
  else
    echo "  Installing Node.js LTS..."
    install_node_linux
  fi
}

install_git() {
  echo "  Installing Git..."
  if [ "$OS" = "macos" ] && [ "$HAS_BREW" = "1" ]; then
    brew install git
  elif [ "$OS" = "macos" ]; then
    install_git_macos_direct
  else
    SUDO=$(sudo_prefix)
    PKG_MGR=$(detect_linux_pkg_manager)
    case "$PKG_MGR" in
      apt) ${SUDO}apt update && ${SUDO}apt install -y git ;;
      dnf) ${SUDO}dnf install -y git ;;
      pacman) ${SUDO}pacman -S --noconfirm git ;;
      *) echo "  Error: No supported package manager found for git." >&2; return 1 ;;
    esac
  fi
}

install_gh() {
  echo "  Installing GitHub CLI..."
  if [ "$OS" = "macos" ] && [ "$HAS_BREW" = "1" ]; then
    brew install gh
  elif [ "$OS" = "macos" ]; then
    install_gh_direct
  else
    SUDO=$(sudo_prefix)
    PKG_MGR=$(detect_linux_pkg_manager)
    case "$PKG_MGR" in
      apt) ${SUDO}apt update && ${SUDO}apt install -y gh ;;
      dnf) ${SUDO}dnf install -y gh ;;
      pacman) ${SUDO}pacman -S --noconfirm gh ;;
      *) install_gh_direct ;;
    esac
  fi
}

install_missing_dependencies() {
  echo ""
  if [ "$NEED_NODE" = "1" ]; then
    install_node
  fi
  if [ "$NEED_GIT" = "1" ]; then
    install_git
  fi
  if [ "$NEED_GH" = "1" ]; then
    install_gh
  fi
}

ensure_dependencies() {
  HAS_BREW=0
  if [ "$OS" = "macos" ] && command -v brew >/dev/null 2>&1; then
    HAS_BREW=1
  fi

  HAS_NVM=0
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    HAS_NVM=1
  fi

  activate_nvm_node_on_path

  scan_dependencies

  if [ "$MISSING_COUNT" = "0" ]; then
    echo "  Dependencies: OK"
    return 0
  fi

  show_dependency_summary

  if prompt_yn "Install these now?"; then
    install_missing_dependencies
    echo "  Dependencies: OK"
    return 0
  fi

  echo "" >&2
  echo "  Cannot continue without required dependencies." >&2
  exit 1
}

ensure_gh_auth() {
  if gh auth status >/dev/null 2>&1; then
    return 0
  fi
  echo "" >&2
  echo "  GitHub authentication is required to download Graft." >&2
  echo "  Launching GitHub login..." >&2
  echo "" >&2
  if [ -e /dev/tty ]; then
    gh auth login --web < /dev/tty || true
  else
    gh auth login --web || true
  fi
  if gh auth status >/dev/null 2>&1; then
    echo "" >&2
    echo "  GitHub authentication successful." >&2
    return 0
  fi
  echo "" >&2
  echo "  GitHub authentication failed." >&2
  echo "  Please run 'gh auth login' and re-run this installer." >&2
  exit 1
}

fetch_url() {
  if [ "$DOWNLOAD_CMD" = "curl" ]; then
    curl -fsSL "$1"
  else
    wget -q -O - "$1"
  fi
}

fetch_version() {
  VERSION_JSON=$(fetch_url "$GRAFT_VERSION_URL")

  VERSION=$(echo "$VERSION_JSON" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

  if [ -z "$VERSION" ]; then
    echo "Error: Could not parse version from ${GRAFT_VERSION_URL}" >&2
    exit 1
  fi

}

download_artifact() {
  PATTERN="$1"
  DEST="$2"
  if [ -n "${GRAFT_ARTIFACTS_URL:-}" ]; then
    if [ "$DOWNLOAD_CMD" = "curl" ]; then
      curl -fsSL -o "$DEST" "${GRAFT_ARTIFACTS_URL}/${PATTERN}"
    else
      wget -q -O "$DEST" "${GRAFT_ARTIFACTS_URL}/${PATTERN}"
    fi
  else
    DL_TEMP=$(mktemp -d)
    DL_RC=0
    gh release download "v${VERSION}" \
      --repo grafana/plugin-graft \
      --pattern "$PATTERN" \
      --dir "$DL_TEMP" \
      --clobber && cp "$DL_TEMP/$PATTERN" "$DEST" || DL_RC=$?
    rm -rf "$DL_TEMP"
    return "$DL_RC"
  fi
}

download_and_install_binary() {
  INSTALL_DIR="${GRAFT_BINARY_DIR:-$HOME/.local/bin}"
  BINARY_NAME="graft-server"
  BINARY_PATTERN="graft-server-${OS}-${ARCH}"

  echo "  Downloading ${BINARY_PATTERN}..."
  mkdir -p "$INSTALL_DIR"
  download_artifact "$BINARY_PATTERN" "$INSTALL_DIR/$BINARY_NAME"

  chmod +x "$INSTALL_DIR/$BINARY_NAME"
  if [ "$OS" = "macos" ]; then
    # com.apple.provenance is a kernel-level attribute set on downloaded files
    # that cannot be removed with xattr -d (silently fails without root).
    # Ad-hoc signed binaries with this attribute are killed by Gatekeeper.
    # Copying to a new file strips all kernel download-tracking attributes.
    BINARY_TMP="$INSTALL_DIR/${BINARY_NAME}.tmp"
    cp "$INSTALL_DIR/$BINARY_NAME" "$BINARY_TMP"
    rm "$INSTALL_DIR/$BINARY_NAME"
    mv "$BINARY_TMP" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
  fi

  echo "  Binary installed to ${INSTALL_DIR}/${BINARY_NAME}"
}

download_and_install_extension() {
  EXTENSION_DIR="${GRAFT_EXTENSION_DIR:-$HOME/Graft/extension}"
  TEMP_DIR=$(mktemp -d)

  echo "  Downloading graft-extension.zip..."
  download_artifact "graft-extension.zip" "$TEMP_DIR/graft-extension.zip"

  rm -rf "$EXTENSION_DIR"
  mkdir -p "$EXTENSION_DIR"
  unzip -q "$TEMP_DIR/graft-extension.zip" -d "$EXTENSION_DIR"
  rm -rf "$TEMP_DIR"

  echo "  Extension extracted to ${EXTENSION_DIR}"
}

detect_chromium() {
  if [ "$OS" = "macos" ]; then
    for app in "Google Chrome.app" "Chromium.app" "Brave Browser.app" "Microsoft Edge.app" "Arc.app"; do
      [ -d "/Applications/$app" ] && return 0
    done
  else
    for exe in google-chrome chromium-browser chromium brave-browser microsoft-edge arc; do
      command -v "$exe" >/dev/null 2>&1 && return 0
    done
  fi
  return 1
}

detect_firefox() {
  if [ "$OS" = "macos" ]; then
    [ -d "/Applications/Firefox.app" ] && return 0
  else
    command -v firefox >/dev/null 2>&1 && return 0
  fi
  return 1
}

download_and_install_firefox_extension() {
  FIREFOX_EXTENSION_DIR="${GRAFT_EXTENSION_DIR_FIREFOX:-$HOME/Graft/extension-firefox}"

  TEMP_DIR=$(mktemp -d)
  FIREFOX_XPI="$TEMP_DIR/graft-extension-firefox.xpi"
  FIREFOX_ZIP="$TEMP_DIR/graft-extension-firefox.zip"

  echo "  Downloading Firefox extension..."
  if download_artifact "graft-extension-firefox.xpi" "$FIREFOX_XPI" 2>/dev/null; then
    mkdir -p "$FIREFOX_EXTENSION_DIR"
    cp "$FIREFOX_XPI" "$FIREFOX_EXTENSION_DIR/graft-extension-firefox.xpi"
    echo "  Signed Firefox extension (.xpi) installed to ${FIREFOX_EXTENSION_DIR}"
  elif download_artifact "graft-extension-firefox.zip" "$FIREFOX_ZIP" 2>/dev/null; then
    rm -rf "$FIREFOX_EXTENSION_DIR"
    mkdir -p "$FIREFOX_EXTENSION_DIR"
    unzip -q "$FIREFOX_ZIP" -d "$FIREFOX_EXTENSION_DIR"
    echo "  Firefox extension extracted to ${FIREFOX_EXTENSION_DIR}"
  else
    echo "  Warning: Firefox extension not found in release" >&2
  fi

  rm -rf "$TEMP_DIR"
}

download_setup_bundle() {
  SETUP_DIR="$HOME/Graft"
  mkdir -p "$SETUP_DIR"
  SETUP_BUNDLE="$SETUP_DIR/graft-setup.bundle.js"

  echo "  Downloading setup bundle..."
  if [ -n "${GRAFT_ARTIFACTS_URL:-}" ]; then
    fetch_url "${GRAFT_ARTIFACTS_URL}/graft-setup.bundle.js" > "$SETUP_BUNDLE"
  elif gh release download "v${VERSION}" \
    --repo grafana/plugin-graft \
    --pattern "graft-setup.bundle.js" \
    --dir "$SETUP_DIR" \
    --clobber 2>/dev/null; then
    echo "  Setup bundle downloaded."
  elif [ -n "${GRAFT_SETUP_URL:-}" ]; then
    fetch_url "$GRAFT_SETUP_URL" > "$SETUP_BUNDLE"
  else
    echo "  Error: Setup bundle not found in release." >&2
    exit 1
  fi
}

download_tool_bundles() {
  GRAFT_DIR="$HOME/Graft"
  mkdir -p "$GRAFT_DIR"

  for BUNDLE_NAME in graft-uninstall.bundle.js graft-update.bundle.js; do
    DEST="$GRAFT_DIR/$BUNDLE_NAME"
    echo "  Downloading ${BUNDLE_NAME}..."
    if [ -n "${GRAFT_ARTIFACTS_URL:-}" ]; then
      if fetch_url "${GRAFT_ARTIFACTS_URL}/${BUNDLE_NAME}" > "$DEST" 2>/dev/null; then
        echo "  ${BUNDLE_NAME} downloaded."
      else
        echo "  Warning: Could not download ${BUNDLE_NAME}" >&2
      fi
    else
      gh release download "v${VERSION}" \
        --repo grafana/plugin-graft \
        --pattern "$BUNDLE_NAME" \
        --dir "$GRAFT_DIR" \
        --clobber 2>/dev/null || echo "  Warning: ${BUNDLE_NAME} not found in release" >&2
    fi
  done
}

run_setup() {
  BINARY_PATH="${GRAFT_BINARY_DIR:-$HOME/.local/bin}/graft-server"
  SETUP_BUNDLE="$HOME/Graft/graft-setup.bundle.js"

  SETUP_ARGS="--binary $BINARY_PATH --version $VERSION"
  if [ "$HAS_CHROMIUM" = "1" ]; then
    EXTENSION_DIR="${GRAFT_EXTENSION_DIR:-$HOME/Graft/extension}"
    SETUP_ARGS="$SETUP_ARGS --extension $EXTENSION_DIR"
  fi
  if [ "$HAS_FIREFOX" = "1" ]; then
    FIREFOX_EXT_DIR="${GRAFT_EXTENSION_DIR_FIREFOX:-$HOME/Graft/extension-firefox}"
    SETUP_ARGS="$SETUP_ARGS --firefox-extension $FIREFOX_EXT_DIR"
  fi

  echo ""
  if ! node "$SETUP_BUNDLE" $SETUP_ARGS; then
    echo "Error: setup bundle failed. Installation may be incomplete." >&2
    exit 1
  fi
}

install_standalone_scripts() {
  INSTALL_DIR="$HOME/.local/bin"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

  mkdir -p "$INSTALL_DIR"

  for SCRIPT_NAME in graft-uninstall graft-update; do
    SRC_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.sh"
    DEST_FILE="${INSTALL_DIR}/${SCRIPT_NAME}"

    if [ -f "$SRC_FILE" ]; then
      cp "$SRC_FILE" "$DEST_FILE"
    elif [ -n "${GRAFT_ARTIFACTS_URL:-}" ]; then
      if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -fsSL -o "$DEST_FILE" "${GRAFT_ARTIFACTS_URL}/${SCRIPT_NAME}.sh" 2>/dev/null || true
      else
        wget -q -O "$DEST_FILE" "${GRAFT_ARTIFACTS_URL}/${SCRIPT_NAME}.sh" 2>/dev/null || true
      fi
    else
      DL_TEMP=$(mktemp -d)
      gh release download "v${VERSION}" \
        --repo grafana/plugin-graft \
        --pattern "${SCRIPT_NAME}.sh" \
        --dir "$DL_TEMP" \
        --clobber 2>/dev/null || true
      if [ -f "$DL_TEMP/${SCRIPT_NAME}.sh" ]; then
        cp "$DL_TEMP/${SCRIPT_NAME}.sh" "$DEST_FILE"
      fi
      rm -rf "$DL_TEMP"
    fi

    if [ -f "$DEST_FILE" ]; then
      chmod +x "$DEST_FILE"
      echo "  Installed ${SCRIPT_NAME} to ${DEST_FILE}"
    fi
  done
}

write_metadata() {
  METADATA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/graft"
  mkdir -p "$METADATA_DIR"
  BINARY_PATH="${GRAFT_BINARY_DIR:-$HOME/.local/bin}/graft-server"
  EXT_DIR="${GRAFT_EXTENSION_DIR:-$HOME/Graft/extension}"
  FIREFOX_EXT_DIR="${GRAFT_EXTENSION_DIR_FIREFOX:-$HOME/Graft/extension-firefox}"

  META_JSON="{ \"version\": \"${VERSION}\", \"binaryPath\": \"${BINARY_PATH}\""
  if [ "$HAS_CHROMIUM" = "1" ]; then
    META_JSON="${META_JSON}, \"extensionDir\": \"${EXT_DIR}\""
  fi
  if [ "$HAS_FIREFOX" = "1" ]; then
    META_JSON="${META_JSON}, \"firefoxExtensionDir\": \"${FIREFOX_EXT_DIR}\""
  fi
  META_JSON="${META_JSON} }"

  echo "$META_JSON" > "$METADATA_DIR/meta.json"
  echo "  Install metadata written to ${METADATA_DIR}/meta.json"
}

ensure_local_bin_on_path() {
  LOCAL_BIN="$HOME/.local/bin"
  mkdir -p "$LOCAL_BIN"

  case ":$PATH:" in
    *":$LOCAL_BIN:"*) ;;
    *) export PATH="$LOCAL_BIN:$PATH" ;;
  esac

  SHELL_NAME="${SHELL:-/bin/sh}"
  SHELL_NAME="${SHELL_NAME##*/}"
  case "$SHELL_NAME" in
    zsh)  PROFILE="$HOME/.zshrc" ;;
    bash) PROFILE="$HOME/.bashrc" ;;
    *)    PROFILE="$HOME/.profile" ;;
  esac

  if [ -f "$PROFILE" ] && command -v grep >/dev/null 2>&1 && grep -q '\.local/bin' "$PROFILE" 2>/dev/null; then
    return 0
  fi

  echo "" >> "$PROFILE"
  echo "# Added by Graft installer" >> "$PROFILE"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
  echo "  Added ~/.local/bin to PATH in $PROFILE"
}

main() {
  OS=$(detect_os)
  ARCH=$(detect_arch)
  check_requirements
  ensure_local_bin_on_path
  ensure_dependencies
  if [ -z "${GRAFT_ARTIFACTS_URL:-}" ] || [ "${GRAFT_REQUIRE_AUTH:-}" = "1" ]; then
    ensure_gh_auth
  fi
  fetch_version

  echo ""
  echo "  Grafana Graft Installer"
  echo "  ======================="
  echo ""
  echo "  Detected OS:   ${OS}"
  echo "  Detected Arch: ${ARCH}"
  echo "  Version:       ${VERSION}"
  echo ""

  HAS_CHROMIUM=0
  if detect_chromium; then
    HAS_CHROMIUM=1
    echo "  Chromium:      detected"
  fi
  HAS_FIREFOX=0
  if detect_firefox; then
    HAS_FIREFOX=1
    echo "  Firefox:       detected"
  fi
  if [ "$HAS_CHROMIUM" = "0" ] && [ "$HAS_FIREFOX" = "0" ]; then
    echo "  Error: No supported browser found (Chrome, Chromium, Brave, Edge, Firefox)." >&2
    echo "  Please install a supported browser and try again." >&2
    exit 1
  fi
  echo ""

  download_and_install_binary
  if [ "$HAS_CHROMIUM" = "1" ]; then
    download_and_install_extension
  fi
  if [ "$HAS_FIREFOX" = "1" ]; then
    download_and_install_firefox_extension
  fi
  download_setup_bundle
  download_tool_bundles
  write_metadata
  install_standalone_scripts
  run_setup

  echo ""
  echo "  To use Graft commands in this terminal, run:"
  echo ""
  echo "    source ~/${PROFILE##*/}"
  echo ""
}

main "$@"
