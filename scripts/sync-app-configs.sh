#!/bin/bash
# Pulls the live, app-owned settings files (Antigravity/Gemini, Codex) into
# this repo so they can be diffed and version-controlled.
#
# These files are rewritten in place by their apps (write-temp + rename), which
# destroys a symlink sitting at that path and forks it into a plain file. So we
# never symlink them — we copy root -> repo on demand instead, then let you
# `git diff` / `git add` / commit whatever you want to keep.
#
# Usage:
#   scripts/sync-app-configs.sh pull   # copy live files into the repo
#   scripts/sync-app-configs.sh diff   # show what would change, without copying

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# root_path:repo_relative_path
PAIRS=(
  "$HOME/.gemini/antigravity-cli/settings.json:.gemini/antigravity-cli/settings.json"
  "$HOME/.codex/config.toml:.codex/config.toml"
  "$HOME/.codex/hooks.json:.codex/hooks.json"
)

cmd="${1:-}"
if [[ "$cmd" != "pull" && "$cmd" != "diff" && "$cmd" != "push" ]]; then
  echo "Usage: $0 {pull|diff|push}" >&2
  exit 1
fi

for pair in "${PAIRS[@]}"; do
  root_path="${pair%%:*}"
  repo_rel="${pair##*:}"
  repo_path="$REPO_ROOT/$repo_rel"

  if [[ ! -f "$root_path" ]]; then
    echo "skip (missing): $root_path"
    continue
  fi

  if [[ "$cmd" == "diff" ]]; then
    echo "--- $repo_rel ---"
    diff -u "$repo_path" "$root_path" 2>/dev/null || true
  elif [[ "$cmd" == "push" ]]; then
    if [[ ! -f "$repo_path" ]]; then
      echo "skip (missing in repo): $repo_rel"
      continue
    fi
    mkdir -p "$(dirname "$root_path")"
    cp "$repo_path" "$root_path"
    echo "pushed: $repo_rel -> $root_path"
  else
    mkdir -p "$(dirname "$repo_path")"
    cp "$root_path" "$repo_path"
    echo "pulled: $root_path -> $repo_rel"
  fi
done

if [[ "$cmd" == "pull" ]]; then
  echo
  echo "Review changes with: git -C $REPO_ROOT status"
fi
