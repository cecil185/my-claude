---
name: search-conversations
description: >-
  Search prior Claude Code conversation history by keyword or topic. Returns matching excerpts
  with file/branch/date context so you can locate the session. Trigger when user says "find
  a past conversation", "what did we discuss about X", "how did we solve X before", "search
  my history for", "look up a previous session", "recall when we", or "search conversations".
model: claude-sonnet-4-6
effort: low
---

# Search Conversations

Search Claude Code conversation history stored in `~/.claude/projects/`.

## Step 1 — Run the search

Run this script as a single bash heredoc. Replace `QUERY_TERMS` with the user's search terms (lowercase, space-separated):

```bash
python3 - QUERY_TERMS <<'PYEOF'
import json, os, sys, re
from pathlib import Path
from datetime import datetime, timezone

terms = [t.lower() for t in sys.argv[1:]]
if not terms:
    print("Usage: pass search terms as arguments")
    sys.exit(1)

projects_dir = Path.home() / ".claude" / "projects"
matches = []

for project_dir in sorted(projects_dir.iterdir()):
    if not project_dir.is_dir():
        continue
    project_name = project_dir.name

    for jsonl_file in sorted(project_dir.glob("*.jsonl")):
        session_id = jsonl_file.stem
        try:
            lines = jsonl_file.read_text().splitlines()
        except Exception:
            continue

        session_meta = {}
        for line in lines[:5]:
            try:
                d = json.loads(line)
                if d.get("type") in ("user", "assistant") and "timestamp" in d:
                    session_meta["timestamp"] = d["timestamp"]
                    session_meta["branch"] = d.get("gitBranch", "")
                    session_meta["cwd"] = d.get("cwd", "")
                    break
            except Exception:
                pass

        for i, line in enumerate(lines):
            try:
                d = json.loads(line)
            except Exception:
                continue

            msg_type = d.get("type")
            if msg_type not in ("user", "assistant"):
                continue

            msg = d.get("message", {})
            content = msg.get("content", "")

            text = ""
            if isinstance(content, str):
                text = content
            elif isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        text += block.get("text", "") + " "

            if not text:
                continue

            text_lower = text.lower()
            if all(t in text_lower for t in terms):
                ts = d.get("timestamp", session_meta.get("timestamp", ""))
                try:
                    dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    ts_fmt = dt.strftime("%Y-%m-%d %H:%M")
                except Exception:
                    ts_fmt = ts[:16] if ts else "unknown"

                idx = text_lower.find(terms[0])
                start = max(0, idx - 60)
                end = min(len(text), idx + 120)
                snippet = text[start:end].replace("\n", " ").strip()
                if start > 0:
                    snippet = "…" + snippet
                if end < len(text):
                    snippet = snippet + "…"

                matches.append({
                    "project": project_name,
                    "session": session_id[:8],
                    "file": str(jsonl_file),
                    "type": msg_type,
                    "ts": ts_fmt,
                    "branch": session_meta.get("branch", ""),
                    "snippet": snippet,
                })

            if len(matches) >= 30:
                break
        if len(matches) >= 30:
            break

if not matches:
    print(f"No matches found for: {' '.join(terms)}")
    sys.exit(0)

print(f"Found {len(matches)} match(es) for: {' '.join(terms)}\n")
for m in matches:
    branch = f" [{m['branch']}]" if m['branch'] else ""
    print(f"[{m['ts']}]{branch} {m['project'][:40]} ({m['type']})")
    print(f"  Session: {m['session']}  File: {m['file']}")
    print(f"  {m['snippet']}")
    print()
PYEOF
```

## Step 2 — Read the full conversation (optional)

If the user wants to see more of a matching conversation, read the `.jsonl` file
directly and extract the thread using:

```bash
python3 - /path/to/session.jsonl <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    for line in f:
        try:
            d = json.loads(line)
        except Exception:
            continue
        t = d.get("type")
        if t not in ("user", "assistant"):
            continue
        msg = d.get("message", {})
        content = msg.get("content", "")
        text = ""
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    text += block.get("text", "") + "\n"
        if text.strip():
            role = "USER" if t == "user" else "ASSISTANT"
            ts = d.get("timestamp", "")[:16]
            print(f"\n--- {role} [{ts}] ---")
            print(text[:800])
            if len(text) > 800:
                print(f"[...{len(text)-800} more chars]")
PYEOF
```

## Output format

- List matches grouped by session, showing date, project/branch, role, and a
  keyword-in-context snippet.
- If 0 matches: suggest alternative terms and offer to broaden the search.
- If > 10 matches: show the 10 most recent and note total count.
- After listing, ask if the user wants to read any full session.

## Scope

Searches `~/.claude/projects/**/*.jsonl` only (local history). Does not search
memory files, CLAUDE.md, or external systems.
