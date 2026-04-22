FROM alpine:3.23

# Install relevant utilties
RUN apk add --no-cache \
  bash \
  curl \
  git \
  jq \
  make

# Go
RUN apk add --no-cache go

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

WORKDIR /workspace

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
