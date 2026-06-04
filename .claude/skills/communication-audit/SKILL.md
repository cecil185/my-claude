---
name: communication-audit
description: >-
  Audits the user's Slack messages and Linear tickets from the past 7 days.
  Scores communication on delegation quality, proactivity, ask clarity,
  openness to feedback, and signal-to-noise. Rates Linear tickets on
  description completeness, definition of done, and bounded scope.
  Sends report to user via private slack messages.
  Use when user wants feedback on their communication or ticket quality.
when_to_use: >-
  Trigger when user says "communication audit", "audit my Slack", "how am I
  communicating", "review my messages", or "how are my tickets written".
model: claude-opus-4-8
effort: high
---

# Communication Audit

**User:** Cecil Ash — `cash@teamworks.com`


## 1. Resolve identities (parallel)

- Slack: `slack_search_users` query `cash@teamworks.com` → get member ID

- Linear: `list_users` → get user ID


## 2. Gather data (parallel)

- Slack: `slack_search_public_and_private` `from:<member_id>` last 7 days. Fetch thread context for substantive replies.

- Linear: `list_issues` createdBy user, `createdAt: "-P7D"`. Fetch full description per ticket.



## 3. Score Slack (1–5 each, real quote per score)

- **Delegation** — explains why, not just what; names person + action + deadline

- **Proactivity** — flags early vs. reacts after things break

- **Ask clarity** — owner + action + deadline present

- **Openness** — invites pushback vs. one-way broadcast

- **Signal-to-noise** — concise and actionable vs. meandering


## 4. Rate Linear tickets (green / yellow / red)

Each ticket: non-empty description, definition of done, why explained, bounded scope. Yellow = specific rewrite hint. Red = called out directly.


## 5. Output - send as slack message to user 
```
## Communication Audit — [date range]

### Executive Summary

[2 sentences - 1 for slack, 1 for linear on what's the patterns holding them back?]

### Slack Scores

| Dimension | Score | Rationale | Example |

|---|---|---|---|

...
**Overall: X/25**

### Linear Tickets

✅ Green: 4 tickets

⚠️ Yellow: 3 tickets — Missing: X. Hint: …

🔴 Red: 2 tickets — [failed checks]
```

Be direct. Quote real messages. Report length should be maximum 100 words.