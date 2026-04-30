# Agent Instructions
## Tools
- Use the fff MCP tools for all file search operations instead of default tools.
- For searching **inside** files (patterns, symbols, strings), use [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) from the shell—not `grep`, `find … -exec grep`, or ad‑hoc recursive search. It respects `.gitignore`, skips most binary files, and is fast on large trees. Examples: `rg 'pattern'`, `rg -l 'pattern'` (paths only), `rg -n 'pattern' dir/`, `rg -t ts 'pattern'` (by file type), `rg --glob '*.md' 'pattern'`. Install on macOS with `brew install ripgrep` if missing.

## No Compound Commands
IMPORTANT - don't use compound commands containing `cd`
Instead, check and change your branch using `pwd` and `cd` as separate Bash tool calls — never compound `cd` with `&&` or `;`.

## Skill Delegation

When a skill is invoked (via Skill tool or `/skill-name`) and its SKILL.md frontmatter includes a `model` field, always delegate to `Agent(model=<model>, ...)` instead of running inline. Extract all necessary context from the current conversation (URLs, ticket IDs, file paths, prior findings) and include it explicitly in the agent prompt — the sub-agent starts with no conversation context.

Frontmatter model → Agent `model` parameter mapping:
- `claude-opus-4-6` or `opus` → `"opus"`
- `claude-sonnet-4-6` or `sonnet` → `"sonnet"`
- `claude-haiku-4-5-*` or `haiku` → `"haiku"`

Exception: if the skill requires context that is impractical to reconstruct in a sub-agent prompt (e.g., a long interactive session), run inline and note the exception.
