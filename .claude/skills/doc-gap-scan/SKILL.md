---
name: doc-gap-scan
description: >-
  Scans Slack, DMs, and Linear to identify and rank documentation gaps for the
  Data Platform team, then posts the top opportunities to #team-eng-data-platform.
  Does not write docs — surfaces WHERE docs are missing and ranks by impact.
  Use when asked to "find doc gaps", "what needs documenting", "doc opportunity scan",
  "identify missing documentation", or "what should we document this week".
when_to_use: >-
  Trigger when user says "find doc gaps", "what needs documenting", "doc scan",
  "identify documentation opportunities", "what should we document", "doc audit",
  or "post doc gaps to Slack".
model: sonnet
effort: medium
---

# Doc Gap Scanner — Data Platform

Identify, rank, and post documentation opportunities for the Data Platform team.
Gathers signals from Slack, DMs, and Linear, then cross-references existing Notion
docs to surface gaps ordered by impact.

**Outputs:** a ranked list posted to `#team-eng-data-platform` — no docs are written.

---

## Step 1 — Gather signals in parallel

Run all four fetches simultaneously.

### 1a. #team-eng-data-platform (past 7 days)

`mcp__claude_ai_Slack__slack_search_public_and_private` with:
- `query: "in:#team-eng-data-platform after:<date 7 days ago YYYY-MM-DD>"`
- Compute the date at runtime; do not hard-code it.

Look for: repeated questions, "how do I…", "where is…", confusion about a process,
someone explaining the same thing twice, anything prefixed with "reminder" or
"heads up, just learned…".

### 1b. Your DMs (past 7 days)

`mcp__claude_ai_Slack__slack_search_public_and_private` with:
- `query: "to:me after:<date 7 days ago YYYY-MM-DD>"`
- `channel_types: "im,mpim"`

Look for: questions you had to answer manually, requests for "how does X work",
any "can you explain…" or "do we have docs on…" messages.

### 1c. New Linear tickets — team DP (past 7 days)

`mcp__claude_ai_Linear_HTTP__list_issues` with:
- `teamKey: "DP"`
- `createdAt: "-P7D"`
- `limit: 100`

Look for: tickets that include the word "document", "runbook", "wiki", "onboarding",
"how to", tickets that required unusually long descriptions explaining existing
behavior (a sign no doc existed), and repeated SPIKE tickets on the same topic.

### 1d. Existing Notion docs index

`mcp__claude_ai_Notion__notion-fetch` the Team Docs root page:
`https://www.notion.so/teamworksoss/Team-Docs-2fae43737ba2802fb028ea23efbaf4fb`

Extract the list of existing pages/sections. This is the **coverage map** — use it
to determine whether each gap already has a doc or is genuinely missing.

---

## Step 2 — Extract gap signals

For each signal collected above, extract a candidate gap with:
- **Topic** — the thing that isn't documented (e.g., "Kafka consumer lag runbook",
  "how to add a new DAG", "incremental read pattern")
- **Signal type** — `repeated-question`, `dm-explanation`, `linear-ticket`,
  `spike-topic`, `onboarding-friction`
- **Frequency** — how many times this topic surfaced across all sources
- **Audience** — who needs this doc (new team member, oncall engineer, data consumer)
- **Urgency hint** — any explicit "we need to write this up" language

Deduplicate across sources — the same topic appearing in a DM and a Slack thread
counts once with higher frequency.

---

## Step 3 — Cross-reference against existing Notion docs

For each candidate, check the Notion coverage map from Step 1d.

- If a doc **exists**: skip the gap (it's covered). If the existing doc is mentioned
  negatively ("the docs are outdated", "the runbook is wrong"), keep the gap but
  tag it `needs-update` instead of `missing`.
- If **no doc exists**: mark it `missing`.

---

## Step 4 — Score and rank

Score each remaining gap on three axes (1–3 each):

| Axis | 1 | 2 | 3 |
|------|---|---|---|
| **Frequency** | Surfaced once | 2–3 times | 4+ times or from multiple sources |
| **Audience reach** | Single person | Small sub-team | Full team or oncall engineer |
| **Cost of absence** | Minor inconvenience | Repeated interruptions | Blocks work or causes incidents |

**Total score = Frequency + Audience reach + Cost of absence** (max 9).

Sort descending. Keep the top 7 gaps for the Slack post; discard the rest.

---

## Step 5 — Compose and send the Slack message

Call `mcp__claude_ai_Slack__slack_send_message` with:
- `channel: "C0A7BPT91HQ"` (#team-eng-data-platform)
- Message body formatted as below.

### Message format

```
*Doc Gap Scan — <today's date, e.g. May 22>* 📋

Scanned Slack (#team-eng-data-platform + DMs) and Linear (past 7 days).
Here are the top documentation opportunities ranked by impact:

*🔴 High impact (score 7–9)*
1. *<Topic>* — <one sentence: what's missing and why it matters>
   Sources: <e.g. "3× in #team-eng-data-platform, 1 DM">

*🟡 Medium impact (score 4–6)*
2. *<Topic>* — <one sentence>
   Sources: <...>
3. *<Topic>* — <one sentence>
   Sources: <...>

*🟢 Lower impact (score 1–3)*
4–7. <Topic> / <Topic> / <Topic> / <Topic>

Existing docs: <Notion Team Docs URL>
Want to claim one? Reply with the number 👇
```

### Formatting rules

- Maximum 7 items total.
- High = score 7–9, medium = 4–6, lower = 1–3.
- Lower-impact items are on one line, slash-separated — no sub-bullets.
- Keep each description to one sentence; no jargon.
- Never reveal sources by name (don't quote specific DMs or name who asked).
- Do not include items tagged `needs-update` unless no `missing` items remain —
  new docs beat updating old ones for impact.
- End with the Notion URL and the "claim one?" CTA.

---

## Step 6 — Report back

After the message is sent, output a short confirmation:

```
Posted <N> documentation opportunities to #team-eng-data-platform.
Top gap: <Topic> (score <X>/9)
```

No other output needed.
