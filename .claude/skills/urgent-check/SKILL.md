---
name: urgent-check
description: >-
  Scan Slack, Gmail, Linear, and Notion for messages that truly can't wait 3
  hours — someone is blocked on you right now. Filters out noise and shows only
  genuinely urgent items so you can enter deep focus without missing a blocker.
  Use when asked to check for urgent messages, do a focus check, or scan for
  anything blocking before going heads-down.
---

# Urgent Check — Deep Focus Gate

Goal: surface only messages where someone **cannot proceed without you in the next 3 hours**. Everything else is noise — ignore it completely.

Run all four platform checks in parallel, then apply the urgency filter, then present a single ranked list.

---

## Urgency Criteria

A message is urgent **only if** one or more of these is true:

- Someone is explicitly waiting on you, blocked by you, or has asked a question and cannot move forward without your answer
- The message contains words like: "blocking", "blocked", "waiting on you", "need you", "urgent", "ASAP", "today", "by EOD", "critical", "production down", "outage", "incident"
- It's a direct message or @mention (not a channel broadcast) from a coworker — **and** the content implies they need a response soon
- A Linear issue is assigned to you and someone has left a comment or changed priority to Urgent/High that mentions needing your input
- The sender is clearly a manager, direct report, or someone you work with daily (not a bot, newsletter, marketing email, or GitHub notification)

**Not urgent:**
- FYIs, announcements, newsletters, Dependabot/CI alerts
- GitHub PR review requests where no one is explicitly waiting
- Group @channel / @here mentions with no direct question to you
- Status updates, meeting recordings, or digest emails
- Linear issue updates where you're just a subscriber (not assignee or mentioned)

---

## Step 1 — Slack: Check DMs and @mentions

Use `mcp__slack__slack_search_public_and_private` with query:
```
to:me OR @cash is:unread after:yesterday
```

Also search for blocking language in recent messages:
```
blocking OR "waiting on" OR "need you" OR urgent is:unread after:yesterday
```

From results, keep only messages where:
- You are directly addressed (`to:me`, `@cash`, your name)
- The content matches urgency criteria above
- Message is from a human (not a bot/integration)

For each candidate, note: channel/DM, sender, timestamp, and the key sentence that makes it urgent.

---

## Step 2 — Gmail: Scan unread inbox

Call `mcp__claude_ai_Gmail__search_threads` with:
- `query: "is:unread is:inbox -category:promotions -category:social -category:updates"`
- `maxResults: 30`

For each thread, read the subject and snippet. Apply urgency filter. Skip anything that looks like:
- Automated notifications (GitHub, Jira, Sentry, CircleCI, newsletters)
- Marketing or promotional content
- Meeting invites that don't require an immediate decision

Keep only threads where a human is waiting for your reply or decision.

---

## Step 3 — Linear: Check for urgent issues and blocking comments

Run these calls in parallel:

1. `mcp__claude_ai_Linear__list_issues` with `assignee: "me"`, `priority: 1` (Urgent) — get any urgent issues assigned to you
2. `mcp__claude_ai_Linear__list_issues` with `assignee: "me"`, `state: "In Progress"` — get your in-progress issues
3. Search for recent comments on your issues: `mcp__claude_ai_Linear__list_comments` — look for comments in the last 6 hours on issues assigned to you

For each item, check if:
- Priority is Urgent (1) or High (2) and someone has commented asking for your input
- A comment mentions you by name or implies they are blocked
- A ticket is due today or marked as blockers

---

## Step 4 — Notion: Check for mentions

Call `mcp__claude_ai_Notion__notion-search` with a query for your name or any recently updated pages you own.

Check for:
- Comments or @mentions directed at you on pages
- Action items assigned to you with today's date

---

## Step 5 — Apply the urgency filter and rank results

From all four sources, keep only items that pass the urgency criteria. Rank them:

1. **Critical** — production incident, explicit "blocked" message, manager asking for immediate response
2. **High** — direct question from coworker where they are waiting, urgent Linear ticket with a blocker comment
3. **Medium** — DM that implies a time-sensitive decision needed today

Discard everything else silently — do not mention what you filtered out.

---

## Output Format

If nothing urgent is found:

```
✓ All clear — no urgent messages found. Safe to go heads-down for 3 hours.
```

If urgent items exist, output **only** this:

```
⚠ X urgent item(s) before you go heads-down:

[CRITICAL]
• Slack @cash from <name> in #<channel> (<time>): "<key sentence>"
• Gmail from <name> (<time>): <subject> — "<key sentence>"

[HIGH]
• Linear <TICKET-ID> — <title>: <name> commented "<key sentence>"

[MEDIUM]
• ...
```

Rules:
- One bullet per item, maximum 2 lines each
- Include only the sentence that makes it urgent — no full message bodies
- No preamble, no explanation of what you searched, no "I checked X platforms"
- After the list, one line: "Respond to these before going heads-down."
- If all clear, say so in one line and nothing else
