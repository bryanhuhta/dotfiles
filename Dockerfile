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

WORKDIR /workspace

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
