# Agent Instructions
## Tools
- Use the fff MCP tools for all file search operations instead of default tools.
- For searching **inside** files (patterns, symbols, strings), use [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) from the shell—not `grep`, `find … -exec grep`, or ad‑hoc recursive search. It respects `.gitignore`, skips most binary files, and is fast on large trees. Examples: `rg 'pattern'`, `rg -l 'pattern'` (paths only), `rg -n 'pattern' dir/`, `rg -t ts 'pattern'` (by file type), `rg --glob '*.md' 'pattern'`. Install on macOS with `brew install ripgrep` if missing.

## No Compound Commands
IMPORTANT - don't use compound commands containing `cd`
Instead, check and change your branch using `pwd` and `cd` as separate Bash tool calls — never compound `cd` with `&&` or `;`.
