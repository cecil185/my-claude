# Auto-backup .zshrc (once per day)
BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y-%m-%d)"
if [ ! -f "$BACKUP_FILE" ]; then
  cp ~/.zshrc "$BACKUP_FILE"
fi

# if .env exists run source .env
[ -f .env ] && source .env

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
eval "$(pyenv virtualenv-init -)"

# Keep only one PATH addition for your tools, after pyenv initialization
export PATH="$HOME/.local/bin:/Users/cecil/.duckdb/cli/latest:/usr/local/sbin:$PATH"
export DBT_PROFILES_DIR=dbt

# Disable welcome messages
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
DISABLE_AUTO_TITLE="true"
touch ~/.hushlogin
unset MAILCHECK

# Zsh and Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=powerlevel10k/powerlevel10k
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ZSH_DISABLE_COMPFIX="true"
source $ZSH/oh-my-zsh.sh

# Tools
export EDITOR="vim"
export KUBECONFIG="$HOME/.kube/config"
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
export VIRTUAL_ENV_DISABLE_PROMPT=true

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Aliases and functions
git_switch_main_and_pull() {
  current_branch=$(git symbolic-ref --short HEAD)
  git switch main && git pull && git switch "$current_branch"
}
alias gsmp='git_switch_main_and_pull'
alias cl='claude'
alias clf='claude --continue --fork-session'

dev-tag() {
  GIT_TIMESTAMP=$(date -u "+%Y%m%d.%H%M%S")
  if [[ $# -eq 1 ]]; then
    echo "Tagging and pushing with dev/$1-$GIT_TIMESTAMP"
    sleep 3
    git tag dev/$1-$GIT_TIMESTAMP
    git push origin dev/$1-$GIT_TIMESTAMP
  else
    echo "Error: requires exactly one argument"
  fi
}
alias gpnv='git push --no-verify'

mr() {      
    local title="$1"
    local target="${2:-main}"                                         
    glab mr create --target-branch "$target" --source-branch "$(git 
  branch --show-current)" --title "$title"                            
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export TEST_VAR="test"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

alias clp="CLAUDE_CONFIG_DIR=~/.claude-personal claude"


nwt() {
  if [[ -z "$1" ]]; then
    echo "usage: nwt <branch-name>" >&2
    return 1
  fi
  local branch="$1"
  local dir="worktrees/${branch//\//-}"
  git worktree add -b "$branch" "$dir" && cursor "$dir"
}

# mngr shell completion (managed; do not edit -- run `mngr extras completion` to refresh)
typeset _mngr_completion="${MNGR_HOST_DIR:-$HOME/.${MNGR_ROOT_NAME:-mngr}}/completions/mngr.zsh"
[[ -r "$_mngr_completion" ]] && source "$_mngr_completion"
unset _mngr_completion


# Added by Antigravity CLI installer
export PATH="/Users/cecil/.local/bin:$PATH"
