#!/bin/bash
# Claude Code PreToolUse hook (Bash matcher).
# Rejects MR/PR creation commands whose --title doesn't start with
# "<TICKET-ID> <type>: " (e.g. "DP-1234 feat: …").
#
# Cheap short-circuit FIRST to avoid spawning jq on every Bash call.

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

set -euo pipefail

command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Anchor to command start so echoed payloads containing these strings don't false-positive
if ! printf '%s' "$command" | grep -qE '^\s*(glab mr create|gh pr create)'; then
  exit 0
fi

title=$(printf '%s' "$command" | sed -nE '
  s/.*--title[= ]"([^"]+)".*/\1/p
  s/.*--title[= ]'\''([^'\'']+)'\''.*/\1/p
' | head -n1)

if [[ -z "$title" ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "MR/PR command must include --title \"<TICKET-ID> <type>: <summary>\" (e.g. --title \"DP-1234 feat: add foo\")."
    }
  }'
  exit 0
fi

if [[ "$title" =~ ^[A-Z]+-[0-9]+\ (feat|fix|chore):\ .+ ]]; then
  exit 0
fi

reason="MR title '$title' is invalid.

Required format: <TICKET-ID> <type>: <summary>

  TICKET-ID  Linear ID, uppercase (e.g. DP-1234, INF-2867)
  type       feat | fix | chore
  summary    short imperative description

Examples:
  DP-1234 feat: add ingestion poller for Catapult
  INF-2867 chore: enforce branch naming
  DP-42 fix: handle empty SQS batches

Rewrite the command with a corrected --title and retry."

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
