---
name: search-conversations
description: >-
  Searches prior Claude Code conversation history by keyword or topic and returns matching
  excerpts with file/branch/date context so you can locate the session. Trigger when user says
  "find a past conversation", "what did we discuss about X", "how did we solve X before", "search
  my history for", "look up a previous session", "recall when we", or "search conversations".
model: claude-sonnet-4-6
effort: low
---

# Search Conversations

Search Claude Code conversation history stored in `~/.claude/projects/`.

## Step 1 — Run the search

Pass the user's search terms (lowercase, space-separated) as arguments. A message matches only
if it contains **all** terms.

```bash
python3 .claude/skills/search-conversations/scripts/search.py <terms...>
```

Example: `python3 .claude/skills/search-conversations/scripts/search.py avro schema`

## Step 2 — Read a full conversation (optional)

If the user wants more of a match, print that session's thread using the `File:` path from Step 1:

```bash
python3 .claude/skills/search-conversations/scripts/read_session.py /path/to/session.jsonl
```

## Output format

- List matches grouped by session: date, project/branch, role, keyword-in-context snippet.
- 0 matches: suggest alternative terms and offer to broaden the search.
- More than 10 matches: show the 10 most recent and note the total.
- After listing, ask whether the user wants to read a full session.

## Scope

`~/.claude/projects/**/*.jsonl` only (local history). Does not search memory files, CLAUDE.md, or
external systems.
