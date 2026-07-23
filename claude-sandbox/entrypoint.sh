#!/bin/bash
set -euo pipefail

# Seed MCP OAuth credentials from the host so plugin integrations
# (e.g. Slack) are authenticated without an interactive login.
if [[ -n "${CLAUDE_CREDENTIALS:-}" ]]; then
  printf '%s' "$CLAUDE_CREDENTIALS" > /home/claude/.claude/.credentials.json
  chmod 600 /home/claude/.claude/.credentials.json
fi
unset CLAUDE_CREDENTIALS

exec claude --dangerously-skip-permissions "$@"
