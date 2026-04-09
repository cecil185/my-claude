---
name: weekly-linear-update
description: >-
  Builds a weekly project update from Linear: progress in the last seven days
  across all issue states for the user’s assigned work, plus a clear “still to
  do” section for To Do and In Progress tickets. Use when the user asks for a
  weekly update, status summary, sprint recap, or “what did I do this week on
  Linear.”
model: sonnet
effort: medium
---

# Weekly Linear Project Update

## When to use

Apply this skill when the user wants a **weekly** rollup of their Linear work: accomplishments over the past week and what remains in **To Do** and **In Progress**.

## Prerequisites

- Follow **[Linear Best Practices](../linear/SKILL.md)** for auth (`mcp_auth` if present), team defaults (**Data & Gen AI**), and assignee default (**Cecil Ash** / `cash@teamworks.com`) unless the user overrides scope (another person, whole team, or specific project).
- **Before calling any Linear tool**, read that tool’s MCP schema (parameters, filters, limits) and use it as written.

## Time window

1. Default: **last 7 calendar days** ending **today** (use the session’s authoritative “today” from user context).
2. If the user names a range (e.g. “since Monday”, “last sprint”), use that instead and state it in the report header.

## Data to pull

Use whatever the Linear MCP exposes (list/search/issues with filters, activity, comments). Prefer **server-side filters** (date, assignee, team, state) when available; otherwise fetch and filter consistently.

### A. Progress this week (all statuses)

Focus on issues **assigned to the user** (unless scope is wider) that had **meaningful movement or touch** in the window:

- **State changes** (e.g. into/out of In Progress, In Review, Done, Cancelled, Triage, Backlog).
- **Updates that indicate progress**: description edits, linked MRs, meaningful comments, sub-issue completion — only include when they clarify the story for stakeholders.

Group the narrative for readability, for example:

- **Shipped / done** — moved to **Done** (or equivalent) in the window; one line per issue (ID, title, optional note).
- **In review / awaiting confirmation** — in **In Review** or blocked on external input if obvious.
- **Active progress** — still **In Progress** but clearly advanced (commits, MR, substantive comment).
- **Other notable motion** — e.g. new prioritization (**To Do**), deprioritized (**Backlog** / **Cancelled**) with short reason if known.

If an issue only had trivial churn with no user-visible progress, **omit or collapse** (“no material updates on X”) rather than padding.

### B. Still to do (To Do + In Progress)

List **all** issues assigned to the user in **To Do** and **In Progress** (use the **exact state names** from their Linear team if they differ slightly).

For each issue: **identifier**, **title**, **state**, and **one short line** on what remains (from description, AC, or last comment — do not invent scope).

## Output format

Produce a **single markdown document** ready to paste into Slack, Notion, or email. Use this structure:

```markdown
## Weekly update — [date range]

### Progress this week
[Grouped bullets or short paragraphs per subsection above; link issues `TEAM-123` when URLs are available from MCP]

### Still to do
**To Do**
- …

**In Progress**
- …

### Notes (optional)
[Blockers, risks, or asks — only if grounded in ticket data or user context]
```

Tone: **factual, concise**, no boilerplate apologies. Prefer **past tense** for completed work and **present/future** for open work.

## Edge cases

- **No issues in the window**: Say so explicitly; still output **Still to do** if any To Do / In Progress exist.
- **MCP unavailable**: Tell the user to configure Linear MCP; do not fabricate tickets.
- **Pagination / limits**: Respect MCP limits; summarize if the list is long (e.g. top by priority or project, with a count of omitted items).
