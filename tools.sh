#!/usr/bin/env bash
# Shareable installer for token-saving AI tool stack - a gum-based TUI
# wizard.
#
# It is a single standalone file - copy it anywhere (Slack/email/USB) and run
# it locally; nothing else from this repo is needed.
#
#   bash setup-ai-tools.sh              # interactive gum wizard
#   bash setup-ai-tools.sh --dry-run    # preview only, install nothing
#
# Self-contained: no nix, no just, no dotfiles checkout. Idempotent - re-run any
# time. Each tool installs via its OWN developer-recommended method, so it keeps

#
# Flags:
#   --dry-run         print what each step would run; install nothing.
set -uo pipefail

DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|--dry) DRY=1 ;;
    -h|--help) awk 'NR>1 && /^#/{sub(/^# ?/,""); print} /^set /{exit}' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

# Interactive only with a TTY. gum is gated on this (set below).
TTY=0; [[ -t 0 && -t 1 ]] && TTY=1
GUM=0   # flips to 1 after gum is confirmed present, if TTY

# ---- plain fallbacks (used when gum is unavailable or non-interactive) -------
if [[ -t 1 ]]; then
  B=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; RED=$'\033[31m'; YLW=$'\033[33m'; RST=$'\033[0m'
else
  B=""; DIM=""; GRN=""; RED=""; YLW=""; RST=""
fi
say()  { printf '%s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$GRN" "$RST" "$*"; }
skip() { printf '  %s-%s %s\n' "$DIM" "$RST" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$RED" "$RST" "$*"; }
plan() { printf '  %s~ would:%s %s\n' "$YLW" "$RST" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
dry()  { [[ "$DRY" == 1 ]]; }

# ---- gum-aware UI wrappers --------------------------------------------------
banner() {
  if [[ "$GUM" == 1 ]]; then gum style --foreground 212 --bold "==> $*"
  else printf '\n%s==> %s%s\n' "$B" "$*" "$RST"; fi
}
confirm() { # confirm "question"  -> 0 yes / 1 no
  [[ "$TTY" == 0 ]] && return 0
  if [[ "$GUM" == 1 ]]; then gum confirm "$1"; return $?; fi
  local reply; printf '%s [Y/n] ' "$1"; read -r reply </dev/tty || return 1
  [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

FAILED=(); INSTALLED=()
run() { # run <label> <cmd...> : ✓/✗, spinner under gum, never fatal
  local label="$1"; shift; local rc
  if dry; then plan "$label  ($*)"; return; fi
  if [[ "$GUM" == 1 ]]; then
    gum spin --spinner dot --title "$label" -- bash -c "$(printf '%q ' "$@") >/tmp/setup-ai-tools.log 2>&1"; rc=$?
  else
    "$@" >/tmp/setup-ai-tools.log 2>&1; rc=$?
  fi
  if [[ $rc -eq 0 ]]; then ok "$label"; INSTALLED+=("$label")
  else bad "$label (see /tmp/setup-ai-tools.log)"; FAILED+=("$label")
       tail -n 3 /tmp/setup-ai-tools.log | sed 's/^/      /' >&2; fi
}

# ---- AXI catalog + selection (defined early so tests can source it) ---------
# From axi.md: "name|tag|description". linear-axi is community but Laszlo
# recommends it, so it ships flagged as such.
# Descriptions are comma-free so gum's comma-separated --selected can pre-check
# every row. Tools we don't use (oracle/clickup/metabase/harvest/jj/cyber-mux)
# are omitted.
AXI_CATALOG=(
  "gh-axi|official|GitHub issues / PRs / workflow runs / releases"
  "chrome-devtools-axi|official|Browser automation - navigate / click / fill / extract"
  "lavish-axi|official|Turn agent HTML artifacts into review surfaces"
  "quota-axi|official|Claude / Codex / Cursor / Copilot / Grok quota usage"
  "linear-axi|community - Laszlo|Linear issues and projects"
  "npm-axi|community|Search / inspect npm packages / versions / downloads"
  "sqlite-axi|community|Read-only SQLite queries / schemas / sample rows"
  "slack-axi|community|Read / search / draft Slack messages"
  "gws-axi|community|Gmail / Calendar / Docs / Drive / Slides"
  "notion-axi|community|Notion pages and databases"
  "databricks-axi|community|Run Databricks jobs / watch runs / pull logs"
  "aws-axi|community|Provision / deploy / inspect AWS services"
  "docker-axi|community|Build / run / debug / publish Docker apps"
  "dynamodb-axi|community|Query / operate DynamoDB tables"
  "pg-axi|community|Query / back up / maintain PostgreSQL"
  "mongodb-axi|community|Query / maintain MongoDB databases"
  "kubernetes-axi|community|Deploy / debug / scale Kubernetes workloads"
  "redis-axi|community|Query / maintain Redis databases"
  "celery-axi|community|Run / monitor / operate Celery task queues"
  "glab-axi|community|GitLab issues / MRs / CI-CD pipelines"
)
# Recommend broadly: the non-interactive default is the whole catalog.
axi_default() { local l; for l in "${AXI_CATALOG[@]}"; do printf '%s\n' "${l%%|*}"; done; }

# These AXI tools aren't published to npm - install them from their GitHub repos
# (npm install -g owner/repo). The rest resolve from the npm registry by name.
AXI_GITHUB=" docker-axi mongodb-axi redis-axi celery-axi dynamodb-axi kubernetes-axi "
axi_spec() { case "$AXI_GITHUB" in *" $1 "*) echo "thatdudealso/$1" ;; *) echo "$1" ;; esac; }

choose_axi() { # prints the chosen bare tool names, one per line
  if [[ "$GUM" != 1 ]]; then axi_default; return; fi   # non-interactive: all
  # gum choose --no-limit: arrow keys, SPACE toggle, ENTER confirm. Show a
  # readable row, then map chosen rows back to bare tool names.
  local rows=() line name tag desc
  for line in "${AXI_CATALOG[@]}"; do
    IFS='|' read -r name tag desc <<<"$line"
    rows+=("$(printf '%-20s (%s) %s' "$name" "$tag" "$desc")")
  done
  # Pre-select every row (--selected='*'): ENTER installs the lot; SPACE
  # deselects the few you won't use. Selected rows are pink, unselected are
  # dim, and the cursor is a background bar so it doesn't read as "selected".
  printf '%s\n' "${rows[@]}" \
    | gum choose --no-limit --height 20 --selected='*' \
        --header "AXI tools - all pre-selected. SPACE to deselect any you won't use, ENTER to install" \
        --selected.foreground 212 \
        --item.foreground 244 \
        --cursor.foreground 0 --cursor.background 212 \
    | awk '{print $1}'
}

# Optional agent tools (heavier, opt-in). Selected in the wizard, default none.
OPTIONAL_CATALOG=(
  "herdr|multi-agent orchestration / crew backend"
  "treehouse|worktree + task workspace manager"
  "no-mistakes|pre-push validation (review / tests / lint / CI)"
)
choose_optional() { # prints the chosen tool names, one per line
  [[ "$GUM" != 1 ]] && return   # non-interactive: install none
  local rows=() line name desc
  for line in "${OPTIONAL_CATALOG[@]}"; do
    IFS='|' read -r name desc <<<"$line"
    rows+=("$(printf '%-14s %s' "$name" "$desc")")
  done
  printf '%s\n' "${rows[@]}" \
    | gum choose --no-limit --height 6 \
        --header "Optional agent tools - SPACE to select any you want, ENTER to confirm (none by default)" \
        --selected.foreground 212 --item.foreground 244 \
        --cursor.foreground 0 --cursor.background 212 \
    | awk '{print $1}'
}

# Test seam: source with SETUP_AI_TOOLS_LIB=1 to get the functions above without
# running the installer.
[[ -n "${SETUP_AI_TOOLS_LIB:-}" ]] && return 0 2>/dev/null

# ==== main wizard ============================================================
banner "Prerequisites"
if ! have brew; then bad "Homebrew missing. Install it first: https://brew.sh"; exit 1; fi
ok "brew"
mkdir -p "$HOME/.local/bin"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
have node || run "node" brew install node
have pipx || run "pipx" brew install pipx
if have pipx; then pipx ensurepath >/dev/null 2>&1 || true; fi
if [[ "$TTY" == 1 ]]; then have gum || run "gum" brew install gum; have gum && GUM=1; fi
have node && ok "node"; have pipx && ok "pipx"; have gum && ok "gum"

if [[ "$GUM" == 1 ]]; then
  gum style --border rounded --margin "1 0" --padding "1 2" --border-foreground 212 \
    "$(gum style --bold --foreground 212 'AI tool stack installer')" \
    "Token-saving CLIs + MCP servers, via each dev's own installer." \
    "Idempotent - safe to re-run."
fi
banner "This will install"
dry && say "  ${YLW}[DRY RUN]${RST} nothing will be installed - showing planned steps only"
say "  headroom, rtk, codegraph, fff-mcp, baby-menu, ponytail (Claude plugin), selected AXI tools"
say "  MCP servers: fff, codegraph, headroom"
say "  optional (pick in wizard): herdr, treehouse, no-mistakes"
confirm "Proceed?" || { say "Aborted."; exit 0; }

banner "Headroom (agent wrapper - the claude alias runs through it)"
# headroom-ai gives the `headroom` binary, headroom gives `max`. Skip if already
# present (use `pipx upgrade headroom-ai` / `pipx upgrade headroom` to update).
if have headroom; then skip "headroom (already installed)"; else run "headroom-ai[all]" pipx install 'headroom-ai[all]'; fi
if have max;      then skip "max (already installed)";      else run "headroom[all]"    pipx install 'headroom[all]'; fi

banner "rtk (token-minimizing CLI proxy)"
if have rtk; then skip "rtk (already installed)"; else run "rtk" brew install rtk; fi

banner "codegraph (code knowledge graph + MCP)"
# The installer drops the binary; we wire the MCP server ourselves below via
# `claude mcp add` (non-interactive). Don't run `codegraph install` here - it
# prompts for which agents to target and would hang under the gum spinner.
if have codegraph; then skip "codegraph (already installed)"
else run "codegraph installer" bash -c 'curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh'; fi

banner "fff-mcp (fast file finder MCP)"
if have fff-mcp; then skip "fff-mcp (already installed)"
else run "fff-mcp installer" bash -c 'curl -L https://dmtrkovalenko.dev/install-fff-mcp.sh | sh'; fi

banner "Baby Menu (menu-bar app with quota/usage widgets)"
if brew list --cask baby-menu >/dev/null 2>&1; then skip "baby-menu (already installed)"
else run "baby-menu" brew install --cask kunchenguid/tap/baby-menu; fi

banner "AXI tools (choose critically - just what you'll use)"
mapfile -t AXI_PICKS < <(choose_axi)
if [[ ${#AXI_PICKS[@]} -eq 0 ]]; then skip "no AXI tools selected"; else
  for t in "${AXI_PICKS[@]}"; do
    [[ -z "$t" ]] && continue
    if have "$t"; then skip "$t (already installed)"; else run "$t" npm install -g "$(axi_spec "$t")"; fi
    if ! dry && have "$t" && "$t" --help 2>&1 | grep -q 'setup hooks'; then
      if "$t" setup hooks >/dev/null 2>&1; then ok "$t hooks"; else skip "$t hooks (none)"; fi
    fi
  done
fi

banner "Optional agent tools (herdr, treehouse, no-mistakes)"
mapfile -t OPT_PICKS < <(choose_optional)
if [[ ${#OPT_PICKS[@]} -eq 0 ]]; then skip "none selected"; else
  for t in "${OPT_PICKS[@]}"; do
    [[ -z "$t" ]] && continue
    if have "$t"; then skip "$t (already installed)"; continue; fi
    case "$t" in
      herdr)       run "herdr"       bash -c 'curl -fsSL https://herdr.dev/install.sh | sh' ;;
      treehouse)   run "treehouse"   bash -c 'curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh' ;;
      no-mistakes) run "no-mistakes" bash -c 'curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh' ;;
    esac
  done
fi

banner "MCP servers (Claude Code, user scope)"
if have claude; then
  add_mcp() { local name="$1"; shift
    # `--` separates the server command from claude's own flags, so args like
    # codegraph's `--mcp` reach the server instead of erroring as claude options.
    if dry; then plan "claude mcp add -s user $name -- $*"; return; fi
    claude mcp remove -s user "$name" >/dev/null 2>&1 || true
    if claude mcp add -s user "$name" -- "$@" >/dev/null 2>&1; then ok "mcp: $name"; else bad "mcp: $name"; fi; }
  if have fff-mcp;   then add_mcp fff "$(command -v fff-mcp)";         else skip "mcp fff (fff-mcp missing)"; fi
  if have codegraph; then add_mcp codegraph codegraph serve --mcp;    else skip "mcp codegraph (missing)"; fi
  if have headroom;  then add_mcp headroom "$(command -v headroom)" mcp serve; else skip "mcp headroom (missing)"; fi
else
  skip "claude CLI not found - skipping MCP wiring (install Claude Code, then re-run)"
fi

banner "ponytail (Claude Code plugin)"
if dry; then
  plan "claude plugin marketplace add DietrichGebert/ponytail && claude plugin install ponytail@ponytail"
elif have claude; then
  claude plugin marketplace add DietrichGebert/ponytail >/dev/null 2>&1 || true
  if claude plugin install ponytail@ponytail >/dev/null 2>&1; then ok "ponytail plugin"; else
    skip "ponytail: run '/plugin marketplace add DietrichGebert/ponytail' then enable ponytail@ponytail"
  fi
else
  skip "claude CLI not found - add DietrichGebert/ponytail plugin manually"
fi

banner "Getting started (per tool)"
say "  ${B}headroom${RST}   ${RED}REQUIRED${RST} - Headroom only saves tokens when Claude runs through it."
say "             Add to your shell rc (~/.zshrc / ~/.bashrc), then restart your shell:"
say "               ${B}alias claude='headroom wrap claude --1m --'${RST}"
say "               ${B}export HEADROOM_OUTPUT_SHAPER=1${RST}"
say "             ${B}headroom doctor${RST} verifies routing; ${B}headroom dashboard${RST} shows savings"
say "  ${B}baby-menu${RST}  menu-bar app with quota/usage widgets - launch it from Spotlight."
say "             ${B}Hint:${RST} add your quota limits so it can track usage; ${B}quota-axi${RST}"
say "             reports your current Claude/Codex/Cursor limits to fill them in"
say "  ${B}rtk${RST}        run ${B}rtk init${RST} once to wire the Claude Code hook; ${B}rtk gain${RST} shows savings"
say "  ${B}codegraph${RST}  run ${B}codegraph init${RST} in each repo you want indexed (creates .codegraph/)."
say "             ${B}codegraph sync${RST} after big changes. Powers the codegraph MCP in Claude Code."
say "  ${B}fff${RST}        MCP auto-wired - the fast file finder is available in Claude Code, no setup"
say "  ${B}ponytail${RST}   plugin enabled - activates in Claude Code (or type /ponytail)"
say "  ${B}AXI tools${RST}  most need a one-time auth, e.g. ${B}gh auth login${RST} (gh-axi),"
say "             or ${B}<tool> auth${RST} / ${B}<tool> --help${RST} for the rest"

banner "Done"
if dry; then say "  ${YLW}[DRY RUN]${RST} no changes made. Re-run without --dry-run to install."; exit 0; fi
[[ ${#INSTALLED[@]} -gt 0 ]] && ok "installed/updated: ${#INSTALLED[@]} items"
[[ ${#FAILED[@]} -gt 0 ]] && { bad "failed: ${FAILED[*]}"; say "  Re-run to retry, or check /tmp/setup-ai-tools.log"; }
say ""
s