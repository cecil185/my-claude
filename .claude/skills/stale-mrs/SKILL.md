---
name: stale-mrs
description: >-
  Identify stale MRs and Linear tickets across the Data Platform team, then
  send each owner a single Slack nudge. Use when asked to check for stale work,
  find idle MRs, or send stale-ticket reminders.
when_to_use: >-
  Trigger when user says "check for stale MRs", "find idle tickets", "nudge the
  team about stale work", "send stale reminders", or "who has work sitting idle".
model: sonnet
effort: medium
disable-model-invocation: true
---

# Stale Work Check

Find work that has gone quiet for 7+ days across GitLab MRs and Linear tickets,
then notify each owner once.

**Stale = no commits, comments, or status changes in the last 7 days.**

---

## Step 1 — Find stale GitLab MRs

Fetch all open MRs from the ingestion group:
`https://gitlab.com/groups/teamworksdev/performance/data-gen-ai/ingestion/-/merge_requests`

Use `mcp__claude_ai_GitLab__search` or the GitLab API. For each MR, check:
- `updated_at` — if older than 7 days and no recent commits or comments → **stale**

---

## Step 2 — Find stale Linear tickets

Fetch all tickets in the DP team (`https://linear.app/teamworks/team/DP`) with
status **Todo** or **In Progress**. Filter to those where `updatedAt` is older
than 7 days with no status changes or comments in that window → **stale**.

---

## Step 3 — Group by owner and notify

For each team member with stale items, send **one** Slack DM using
`mcp__slack__slack_send_message` with this template:

```
Hey [name] 👋 Friendly reminder — these have had no activity for 7+ days.
Consider closing MRs that are no longer needed and updating or closing
Linear tickets.

- [MR title] — [MR URL]
- [Ticket ID]: [Ticket title] — [Linear URL]
```

Rules:
- One message per person, consolidating all their stale items.
- Only ping people who have stale items — skip people who are clear.
- If a person has stale MRs but no stale tickets (or vice versa), omit the
  empty section from their message.
