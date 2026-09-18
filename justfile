# Push repo-owned configs back to live app locations (~/.gemini/..., ~/.codex/...)
sync-push:
    ./scripts/sync-app-configs.sh push

# Pull live app-owned config (Antigravity settings.json, Codex config.toml/hooks.json)
sync-pull:
    ./scripts/sync-app-configs.sh pull

sync-diff:
    ./scripts/sync-app-configs.sh diff

sync-zshrc:
    cp -f ~/.zshrc ./.zshrc