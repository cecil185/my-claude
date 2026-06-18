---
name: sourcebot-search
description: >-
  Search, read, and analyze code across all ingestion repos using Sourcebot. Covers all repos:
  ingestion, ingestion-dags, ingestion-helm, ingestion-argo, ingestion-terraform. Trigger when
  user says "find where X is defined", "show me all usages of Y", "read the file at path Z",
  "how does X work", "search the codebase for", "trace the call path for", "diff commits",
  or "what changed in commit".
model: claude-sonnet-4-6
effort: high
---

# Sourcebot Search

Use the Sourcebot MCP tools to search and read code across all repos in the
Teamworks ingestion platform.

## Tool reference

| Tool | When to use |
|------|-------------|
| `mcp__sourcebot__grep` | Find a symbol, string, or pattern by regex |
| `mcp__sourcebot__glob` | Discover files matching a path pattern |
| `mcp__sourcebot__read_file` | Read source code; use `startLine`/`endLine` to limit output |
| `mcp__sourcebot__list_tree` | Browse directory structure |
| `mcp__sourcebot__list_repos` | See all available repos |
| `mcp__sourcebot__find_symbol_definitions` | Locate where a symbol is declared |
| `mcp__sourcebot__find_symbol_references` | Find all usages of a symbol |
| `mcp__sourcebot__list_commits` | Commit history with optional search/date filters |
| `mcp__sourcebot__get_diff` | Structured diff between two git refs |
| `mcp__sourcebot__ask_codebase` | Natural-language query when grep/glob won't cut it |

## Process

1. Start with `list_repos` if the target repo is unknown.
2. For a known identifier: use `find_symbol_definitions` or `grep` first.
3. Read the top 1–2 results with `read_file` (narrow line range where possible).
4. Stop after 3 tool calls unless the user asks for deeper analysis.
5. For open-ended questions ("how does X work?"), use `ask_codebase`.

## Output format

- Lead with the direct answer or the relevant code snippet.
- Include `repo:path:line` references so the user can navigate directly.
- Keep prose minimal — code and file locations speak for themselves.
- No summaries of what tools you called; just results.

## Example

User: "Where is `BasePoller` defined and what classes extend it?"

1. `find_symbol_definitions("BasePoller")` → `ingestion/platform_ingestion/poller/base_poller.py:12`
2. `find_symbol_references("BasePoller")` → finds `DynamoPoller`, `ForceDecksPoller`, `SmartSpeedPoller`
3. `read_file` on each to confirm inheritance

Output:
```
`BasePoller` defined at ingestion:platform_ingestion/poller/base_poller.py:12

Subclasses:
- DynamoPoller — platform_ingestion/poller/dynamo_poller.py:8
- ForceDecksPoller — platform_ingestion/poller/force_decks_poller.py:6
- SmartSpeedPoller — platform_ingestion/poller/smart_speed_poller.py:5
```
