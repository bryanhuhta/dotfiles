FROM alpine:3.23

# Install relevant utilties
RUN apk add --no-cache \
  bash \
  curl \
  git \
  github-cli \
  jq \
  make \
  sqlite \
  neovim

# Go
# Alpine pins GOTOOLCHAIN=local; auto lets go fetch newer toolchains on demand
RUN apk add --no-cache go
ENV GOTOOLCHAIN=auto

# gcx
RUN GOBIN=/usr/local/bin go install github.com/grafana/gcx/cmd/gcx@latest && \
  go clean -modcache -cache

# Python
RUN apk add --no-cache \
  python3 \
  py3-pip

# Node
RUN apk add --no-cache \
  nodejs \
  npm \
  yarn

# Create non-root user
RUN adduser -D claude
USER claude

# Install claude-code
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/claude/.local/bin:$PATH"

# Disable auto-updater in container
ENV DISABLE_AUTOUPDATER=1

# Pre-configure Claude Code to skip interactive onboarding prompts
RUN mkdir -p /home/claude/.claude
COPY --chown=claude:claude claude-sandbox/claude-settings.json /home/claude/.claude/settings.json
COPY --chown=claude:claude claude-sandbox/claude-state.json /home/claude/.claude.json

# Copy user-level Claude configurations
COPY --chown=claude:claude claude-home/CLAUDE.md /home/claude/.claude/CLAUDE.md
COPY --chown=claude:claude claude-home/skills/ /home/claude/.claude/skills/

# Slack plugin; its MCP OAuth credentials are injected at runtime by the
# sandbox script via CLAUDE_CREDENTIALS (marketplace add tolerates the
# marketplace already being registered)
RUN claude plugin marketplace add anthropics/claude-plugins-official || true && \
  claude plugin install slack@claude-plugins-official

# Neovim configuration
ENV EDITOR=nvim
RUN mkdir -p /home/claude/.config/nvim
COPY --chown=claude:claude private_dot_config/nvim/ /home/claude/.config/nvim/
RUN nvim --headless "+Lazy! sync" +qa

WORKDIR /workspace

# Entrypoint writes runtime-injected credentials before starting Claude
COPY --chown=claude:claude claude-sandbox/entrypoint.sh /home/claude/entrypoint.sh
ENTRYPOINT ["/home/claude/entrypoint.sh"]
