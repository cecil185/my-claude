---
name: team-standup
description: >-
  Generate a team standup showing yesterday's Linear ticket status changes for
  all Data Platform teammates. Use when asked for a team standup or team daily update.
model: sonnet
effort: medium
---

# Team Standup Generator

For each teammate (alphabetical order), show what Linear tickets changed status in the last 24 hours.

**Teammates:**
- Cecil Ash
- Christopher Sparano-Huiban
- Jonas Leuckx
- Laszlo Horanszky
- Scott Roberts

---

## Step 1 — Fetch recent tickets for all teammates in parallel

For each teammate, call `mcp__claude_ai_Linear_HTTP__list_issues` with:
- `assignee: "<full name>"`
- `updatedAt: "-P3D"`
- `limit: 250`

Run all five calls in parallel.

---

## Step 2 — Identify actual status changes

From each person's results, identify tickets where `startedAt`, `completedAt`, or `canceledAt` falls within the last 3 days. Ignore tickets where only `updatedAt` changed (description/label edits, not status moves).

Status change types to include:
- Moved to **Done** (`completedAt` within 24h)
- Moved to **In Progress** (`startedAt` within 24h, current status is In Progress)
- Moved to **In Review** (`startedAt` within 24h, current status is In Review)
- Moved to **Canceled** (`canceledAt` within 24h)

---

## Step 3 — Format the Slack message

One block per person, separated by `---`. Alphabetical order.

```
*Cecil Ash*
*Yesterday*
- DP-812 Done: Core incremental read via `hudi_table_changes()`
- DP-825 In Review: Fix lead_time_seconds never firing

---
*Christopher Sparano-Huiban*
*Yesterday*
- (no status changes)

---
*Jonas Leuckx*
*Yesterday*
- (no status changes)

---
*Laszlo Horanszky*
*Yesterday*
- DP-897 In Progress: Anonymize UTEXAS data for ask_tw

---
*Scott Roberts*
*Yesterday*
- (no status changes)
```

### Formatting rules

- Keep ticket titles short — strip boilerplate like "Phase N:", "feat:", "fix:" prefixes where they add no meaning.
- Use `(no status changes)` when a person has no qualifying events.
- Output plain Slack-compatible markdown. Use `*Name*` and `*Yesterday*` for headers (not `**`).
- No date header at the top.
- No Today section.
