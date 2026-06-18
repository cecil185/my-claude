---
name: slack-faq-summary
description: >-
  Scans #ai-champions, #ai-talk, and #ai-dev-talk for the past month, clusters recurring
  questions, and presents a numbered list. Then asks which topics to draft documentation for.
  Trigger when user says "slack faq", "summarize AI questions", "what are people asking in AI
  slack", "what should we document from slack", "common questions from slack", or "faq from
  ai channels".
model: sonnet
effort: medium
---

# Slack FAQ Summary

Scan three AI Slack channels for the past 30 days, surface the most commonly asked
questions, then offer to draft docs for any of them.

---

## Step 1 — Fetch messages (parallel)

Compute the date 30 days before today. Call `mcp__claude_ai_Slack__slack_search_public_and_private`
for each channel simultaneously:

- `query: "in:#ai-champions after:<YYYY-MM-DD>"`
- `query: "in:#ai-talk after:<YYYY-MM-DD>"`
- `query: "in:#ai-dev-talk after:<YYYY-MM-DD>"`

Flag as question signals: explicit questions, "how do I…", "where is…", "does anyone know…",
repeated explanations, threads with 3+ replies.

---

## Step 2 — Cluster and rank

Group related signals into topics. For each topic record: name, frequency (how many
distinct messages), channels it appeared in, and 1–2 example quotes.

Sort descending by frequency. Keep the top 6.

---

## Step 3 — Output numbered list

```
**AI Slack FAQ — <today's date>**
Channels: #ai-champions · #ai-talk · #ai-dev-talk | Past 30 days

1. **<Topic>** (N mentions, #channel, #channel)
   > "<example quote>"

2. **<Topic>** ...

...
```

---

## Step 4 — Ask which to document

After the list:

```
Which of these would you like me to draft documentation for?
Enter numbers (e.g. 1, 3) or "all" for the top 5.
```

For each selected number, invoke the `/write-docs` skill with the topic name and
example questions as context. Process sequentially.
