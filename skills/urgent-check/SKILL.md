---
name: urgent-check
description: >-
  Scans Slack, Gmail, Linear, and Notion for messages that truly can't wait 3
  hours — someone is blocked on you right now — and returns only the genuinely
  urgent items, filtering out everything else. Trigger when user says "anything
  urgent?", "check for blockers", "focus check", "safe to go heads-down?",
  "anyone waiting on me?", or "scan for urgent messages".
model: sonnet
effort: medium
---

# Urgent Check — Deep Focus Gate

Surface only messages where someone **cannot proceed without you in the next 3 hours**. Everything else is noise.

Run all four platform checks in parallel, then apply the urgency filter, then present one ranked list.

---

## Urgency criteria

Urgent **only if** one or more holds:

- Someone is explicitly waiting on you, blocked by you, or asked a question they can't move past without your answer
- Contains: "blocking", "blocked", "waiting on you", "need you", "urgent", "ASAP", "today", "by EOD", "critical", "production down", "outage", "incident"
- A DM or @mention from a human coworker whose content implies a soon-response
- A Linear issue assigned to you where someone commented or raised priority to Urgent/High asking for your input
- Sender is a manager, direct report, or daily collaborator — not a bot, newsletter, or notification

**Not urgent:** FYIs, announcements, newsletters, Dependabot/CI alerts, PR review requests with nobody waiting, `@channel`/`@here` with no direct question, status updates, digests, Linear issues where you're only a subscriber.

---

## Step 1 — Slack

Compute `AFTER` = yesterday's date as `YYYY-MM-DD` at runtime (never a literal).

Run these five `mcp__slack__slack_search_public_and_private` calls in parallel:

| # | query | channel_types |
|---|---|---|
| 1 | `to:me after:<AFTER>` | `im,mpim` |
| 2 | `in:<#C0APZDC6Y20> after:<AFTER>` (#alerts-data-platform-datadog) | default |
| 3 | `in:<#C0A7BPT91HQ> after:<AFTER>` (#team-eng-data-platform) | default |
| 4 | `in:<#C0AQQ4DSVEU> after:<AFTER>` (#alerts-data-platform-merge-requests) | default |
| 5 | `blocking OR "waiting on" OR "need you" OR urgent after:<AFTER>` | `public_channel,private_channel,mpim,im` |

Keep a result only if you are directly addressed (`to:me`, `@cash`, your name), it matches the urgency criteria, and the sender is human. Note channel/DM, sender, timestamp, and the single sentence that makes it urgent.

## Step 2 — Gmail

`mcp__claude_ai_Gmail__search_threads` with `query: "is:unread is:inbox -category:promotions -category:social -category:updates"`, `maxResults: 100`.

Apply the urgency filter to subject + snippet. Keep only threads where a human awaits your reply or decision.

## Step 3 — Linear

In parallel:
1. `mcp__claude_ai_Linear_HTTP__list_issues` — `assignee: "me"`, `priority: 1`
2. `mcp__claude_ai_Linear_HTTP__list_issues` — `assignee: "me"`, `state: "In Progress"`
3. `mcp__claude_ai_Linear_HTTP__list_comments` — comments in the last 24h on issues assigned to you

Keep items where priority is Urgent/High **and** someone commented asking for input, a comment mentions you or implies they're blocked, or the ticket is due today.

## Step 4 — Notion

`mcp__claude_ai_Notion__notion-search` for your name and recently updated pages you own. Keep @mentions/comments directed at you and action items assigned to you dated today.

## Step 5 — Rank

1. **Critical** — production incident, explicit "blocked", manager needing an immediate response
2. **High** — coworker's direct question they're waiting on; urgent Linear ticket with a blocker comment
3. **Medium** — DM implying a decision needed today

Discard everything else silently — never mention what you filtered out.

---

## Output format

If nothing urgent:

```
✓ All clear — no urgent messages found. Safe to go heads-down for 3 hours.
```

Otherwise output **only**:

```
⚠ X urgent item(s) before you go heads-down:

[CRITICAL]
• Slack @cash from <name> in #<channel> (<time>): "<key sentence>"
• Gmail from <name> (<time>): <subject> — "<key sentence>"

[HIGH]
• Linear <TICKET-ID> — <title>: <name> commented "<key sentence>"

[MEDIUM]
• ...

Respond to these before going heads-down.
```

One bullet per item, max 2 lines. Include only the sentence that makes it urgent — no full bodies, no preamble, no account of what you searched.
