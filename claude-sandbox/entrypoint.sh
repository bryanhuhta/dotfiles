#!/bin/bash
set -euo pipefail

# Seed Claude Code credentials from the host so Claude itself (OAuth)
# and plugin MCP integrations (e.g. Slack) are authenticated without an
# interactive login.
if [[ -n "${CLAUDE_CREDENTIALS:-}" ]]; then
  printf '%s' "$CLAUDE_CREDENTIALS" > /home/claude/.claude/.credentials.json
  chmod 600 /home/claude/.claude/.credentials.json
fi
unset CLAUDE_CREDENTIALS

exec claude --dangerously-skip-permissions "$@"
