#!/bin/bash
# Claude Code PreToolUse hook for Linear MCP tools.
# When creating a new Linear issue (save_issue with no `id`), require
# assigneeId to be set — tickets must always be assigned to cash@teamworks.com.
#
# Also covers ad-hoc Bash invocations of a `linear` CLI.

OWNER_EMAIL="cash@teamworks.com"

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

set -euo pipefail

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

emit_deny() {
  local reason=$1
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

case "$tool" in
  Bash)
    command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    case "$command" in
      *"linear "*"issue"*"create"*|*"linear "*"create"*"issue"*) ;;
      *) exit 0 ;;
    esac
    if printf '%s' "$command" | grep -qE -- '(-a|--assignee)[= ]'; then
      exit 0
    fi
    emit_deny "Linear ticket created via CLI must be assigned to $OWNER_EMAIL. Add --assignee \"$OWNER_EMAIL\" (or the matching Linear username) and retry."
    ;;

  *save_issue*)
    issue_id=$(printf '%s' "$input" | jq -r '.tool_input.id // empty')
    assignee=$(printf '%s' "$input" | jq -r '(.tool_input.assigneeId // .tool_input.assignee) // empty')

    if [[ -n "$issue_id" ]]; then
      exit 0
    fi

    if [[ -n "$assignee" ]]; then
      exit 0
    fi

    emit_deny "New Linear issues must always be assigned to $OWNER_EMAIL. Look up the user via list_users (query: \"$OWNER_EMAIL\") and pass their id as assigneeId on save_issue. Retry once assigneeId is set."
    ;;

  *)
    exit 0
    ;;
esac
