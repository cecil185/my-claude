# Pull live app-owned config (Antigravity settings.json, Codex config.toml/hooks.json)
sync:
    ./scripts/sync-app-configs.sh pull

sync-diff:
    ./scripts/sync-app-configs.sh diff
