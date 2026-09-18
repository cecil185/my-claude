#!/bin/bash
# Installs oh-my-zsh (if missing) and clones the custom plugins and theme
# this setup uses. Safe to re-run: existing installs are skipped.
#
# After running this, symlink your zshrc from this repo:
#   ln -sf ~/Code/me/my-claude/.zshrc ~/.zshrc
#
# Usage:
#   scripts/setup-zsh.sh

set -euo pipefail

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"

# 1. Install oh-my-zsh (KEEP_ZSHRC so an existing ~/.zshrc is untouched;
#    --unattended skips the chsh prompt and the exec-into-zsh at the end)
if [[ -d "$ZSH_DIR" ]]; then
  echo "skip (exists): oh-my-zsh at $ZSH_DIR"
else
  echo "installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended --keep-zshrc
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# 2. Clone custom plugins and theme
#    repo_url:path_relative_to_custom[:extra git clone flags]
REPOS=(
  "https://github.com/zsh-users/zsh-autosuggestions:plugins/zsh-autosuggestions:"
  "https://github.com/zsh-users/zsh-syntax-highlighting:plugins/zsh-syntax-highlighting:"
  "https://github.com/romkatv/powerlevel10k.git:themes/powerlevel10k:--depth=1"
)

for entry in "${REPOS[@]}"; do
  url="${entry%%:*}"
  rest="${entry#*:}"
  rel="${rest%%:*}"
  flags="${rest#*:}"
  dest="$ZSH_CUSTOM_DIR/$rel"

  if [[ -d "$dest" ]]; then
    echo "skip (exists): $rel"
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  # shellcheck disable=SC2086
  git clone $flags "$url" "$dest"
  echo "cloned: $rel"
done

echo
echo "Done. Make sure ~/.zshrc sets:"
echo '  ZSH_THEME="powerlevel10k/powerlevel10k"'
echo '  plugins=(... zsh-autosuggestions zsh-syntax-highlighting)'
