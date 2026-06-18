---
name: unanswered-slack-threads
description: >-
  Scans #team-eng-data-platform, #alerts-data-platform-merge-requests, and #proj-ams-data-platform
  for threads from the past 21 days (excluding the last 3 days) that appear to need a response —
  unanswered questions, blocked requests, or waiting approvals. Flags each with channel, poster,
  link, summary, and days open. Then replies in each flagged thread asking if it still needs
  attention. Trigger when user says "check for unanswered threads", "any open questions in slack",
  "find stale threads", "who's still waiting", "follow up on open threads", or "scan data platform
  channels for unanswered messages".
model: opus
effort: high
---

# Unanswered Slack Threads

Scan three data-platform Slack channels for threads that appear to need a
response, then follow up in each one.

---

## Date window

Compute at runtime:
- `START_DATE` = today − 21 days (format: `YYYY-MM-DD`)
- `END_DATE` = today − 3 days (format: `YYYY-MM-DD`)

Messages **before** `START_DATE` or **after** `END_DATE` are out of scope.

---

## Step 1 — Search each channel (parallel)

Call `mcp__claude_ai_Slack__slack_search_public_and_private` for each channel
simultaneously:

| Channel | Known ID | Query |
|---------|----------|-------|
| #team-eng-data-platform | C0A7BPT91HQ | `in:#team-eng-data-platform after:START_DATE before:END_DATE` |
| #alerts-data-platform-merge-requests | C0AQQ4DSVEU | `in:#alerts-data-platform-merge-requests after:START_DATE before:END_DATE` |
| #proj-ams-data-platform | (look up) | `in:#proj-ams-data-platform after:START_DATE before:END_DATE` |

If the #proj-ams-data-platform channel ID is unknown, call
`mcp__claude_ai_Slack__slack_search_channels` with query `proj-ams-data-platform`
to find it first.

---

## Step 2 — Check each thread for resolution

For every message returned in Step 1, call
`mcp__claude_ai_Slack__slack_read_thread` to fetch all replies. Then apply
the criteria below.

### Flag as UNANSWERED if ANY of these is true:
- The message contains a question (`?`, "anyone know", "can someone", "help with", "how do I", "what is", "when will", "is there") and has **zero replies**
- Someone is clearly waiting: "waiting on", "need approval", "blocked by", "can you review", "LGTM?", "who owns"
- The last reply is from someone other than the original poster and contains no resolution signal
- There's only one message (no replies) and it reads as a request or question

### Skip (treat as RESOLVED) if ANY of these is true:
- Thread contains ✅, 👍, or any thumbs-up/checkmark reaction or emoji
- Thread contains closing language: "thanks", "got it", "resolved", "done", "fixed", "merged", "closing", "nevermind", "nvm", "will do", "on it"
- The original poster themselves replied last (implies self-resolution or follow-up)
- The message is from a bot/integration with no human question attached (e.g. automated CI alerts with no "can someone look at this")

---

## Step 3 — Output results

Present flagged threads sorted by:
1. **Explicit blockers / stakeholder questions** first (contains "blocked", "blocking", "urgent", "ASAP", or from a manager/stakeholder)
2. Then **oldest unanswered first** (largest days-open value)

For each flagged thread output:

```
**Channel:** #<channel-name>
**Poster:** <display name> · <timestamp>
**Link:** <Slack thread URL or permalink>
**Summary:** <one sentence — what is being asked or waited on>
**Days open:** <N days>
```

Separate entries with a blank line. If no unanswered threads are found, output:

```
✓ No unanswered threads found in the scanned channels for the past 18-day window.
```

---

## Step 4 — Follow up in each flagged thread

After presenting the list, confirm with the user before posting:

> Found N unanswered thread(s). Reply in each one asking if it still needs
> attention? (yes/no)

If the user confirms, for each flagged thread call
`mcp__claude_ai_Slack__slack_send_message` to post a reply. Address the
original poster by name. Keep the message friendly and brief:

```
Hey <poster first name> 👋 — just checking in on this thread. Is this still
something that needs attention, or has it been sorted out? Happy to help loop
in the right person if needed!
```

Do **not** post if:
- The thread already has a recent reply (within the last 48 hours)
- The user declines

Report back: "Replied in N thread(s)." or list any failures.
