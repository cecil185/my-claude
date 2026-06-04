---
name: new-doc-skill-opportunities
description: >-
  Scans Slack, DMs, and Linear to identify knowledge gaps for any team —
  missing Notion docs or team Claude skills — and surfaces the top 3
  opportunities. Each opportunity recommends Notion vs skill (or both), with
  links, content outline, and a skill workflow sketch when a skill is the
  better fit. Does not write docs or skills — surfaces gaps and how to close
  them.
  Use when asked to "find doc gaps", "what needs documenting", "doc opportunity scan",
  "identify missing documentation", "skill gaps", or "what should we document this week".
when_to_use: >-
  Trigger when user says "find doc gaps", "what needs documenting", "doc scan",
  "skill gap scan", "identify documentation opportunities", "what should we document",
  "doc audit", "team skill opportunities", or "post doc gaps to Slack".
model: sonnet
effort: medium
---

# Knowledge Gap Scanner

Identify the top 3 knowledge opportunities for a team.
Gathers signals from Slack, DMs, and Linear, then cross-references existing Notion
docs **and** team Claude skills to surface the most impactful gaps — with a clear
recommendation for each: **Notion doc**, **Claude skill**, or **both**.

**Outputs:** 3 richly described opportunities for new docs or skills that will help the team save time

---

## Step 0 — Gather team configuration

Before fetching any data, ask the user for their team-specific details in a single message:

> To run the scan, I need a few details:
> 1. **Slack channel(s)** — Which channel(s) should I scan? (e.g. `#team-eng-data-platform`) — comma-separate if multiple
> 2. **Notion root page URL** — Your team's docs root page (or leave blank to skip Notion)
> 3. **Linear team key** — e.g. `DP`, `ENG`, `PROD` (or leave blank to skip Linear)
> 4. **Skills directory path** — Where your team Claude skills live (or leave blank to skip)

Wait for the user's reply. Store the four values as:
- `CHANNELS` — list of channel names, parsed from the comma-separated input
- `NOTION_URL` — the Notion root page URL, or null
- `LINEAR_KEY` — the Linear team key string, or null
- `SKILLS_DIR` — the filesystem path, or null

Then proceed to Step 1.

---

## Step 1 — Gather signals in parallel

Run all fetches simultaneously using the team configuration from Step 0.

### 1a. Team Slack channel(s) (past 30 days)

For each channel provided, run `mcp__claude_ai_Slack__slack_search_public_and_private` with:
- `query: "in:<channel> after:<date 30 days ago YYYY-MM-DD>"`
- Compute the date at runtime; do not hard-code it.

Look for: repeated questions, "how do I…", "where is…", confusion about a process,
someone explaining the same thing twice, anything prefixed with "reminder" or
"heads up, just learned…". Also: "can Claude…", "is there a skill for…", manual
runbook steps pasted into thread, oncall playbooks explained ad hoc.

### 1b. Your DMs (past 30 days)

`mcp__claude_ai_Slack__slack_search_public_and_private` with:
- `query: "to:me after:<date 30 days ago YYYY-MM-DD>"`
- `channel_types: "im,mpim"`

Look for: questions you had to answer manually, requests for "how does X work",
any "can you explain…" or "do we have docs on…" messages. Repeated multi-step
walkthroughs you gave more than once are strong **skill** candidates.

### 1c. New Linear tickets (past 30 days)

Skip if the user left the Linear team key blank.

`mcp__claude_ai_Linear_HTTP__list_issues` with:
- `teamKey: "<user-provided team key>"`
- `createdAt: "-P30D"`
- `limit: 100`

Look for: tickets that include "document", "runbook", "wiki", "onboarding",
"how to", "skill", "Claude", "agent"; tickets with unusually long descriptions
explaining existing behavior (sign no doc existed); repeated SPIKE tickets on
the same topic; chores to automate a recurring workflow.

### 1d. Existing Notion docs index

Skip if the user left the Notion URL blank.

`mcp__claude_ai_Notion__notion-fetch` the provided root page URL.

Extract the list of existing pages/sections. This is the **Notion coverage map**.

### 1e. Existing team Claude skills index

Skip if the user left the skills directory blank.

List and read frontmatter from every team skill in the provided directory:

```bash
find <skills-directory> -iname 'SKILL.md' -o -iname 'skill.md'
```

For each file, extract `name` and `description` (and `when_to_use` if present).
This is the **skills coverage map** — use it to avoid recommending skills that
already exist and to spot gaps where a skill would duplicate a thin doc.

---

## Step 2 — Extract gap signals

For each signal collected above, extract a candidate gap with:
- **Topic** — what's missing (e.g., "deploy rollback runbook", "how to add a new integration")
- **Signal type** — `repeated-question`, `dm-explanation`, `linear-ticket`,
  `spike-topic`, `onboarding-friction`, `manual-workflow`, `agent-request`
- **Frequency** — how many times this surfaced across sources
- **Audience** — who needs this (new hire, oncall, data consumer)
- **Source links** — Slack permalinks and Linear ticket URLs
- **Urgency hint** — explicit "we need to write this up" language
- **Recommended format** — `notion`, `skill`, or `both` (see decision guide below)

Deduplicate across sources — same topic in DM + channel counts once with higher frequency.

### Notion vs Claude skill — decision guide

Assign **one** primary recommendation per gap (`notion` or `skill`). Use `both` only
when reference material and an executable workflow are clearly separate needs.

| Prefer **Notion doc** | Prefer **Claude skill** | Prefer **both** |
|------------------------|-------------------------|------------------|
| Stable facts, architecture, policies | Repeatable process with tool calls (MCP, AWS, Datadog, git) | Long reference + same workflow run often |
| Read by humans without Claude (stakeholders, audit) | Same steps every time; benefits from live repo/infra context | Onboarding doc + day-one agent helper |
| Browsable sections, diagrams, glossary | Triggered by natural language in chat | Runbook in Notion; skill executes checks and links to it |
| Changes rarely; link from many places | Secrets stay in agent env; queries use authenticated MCP | |

**Skill-fit signals from Slack/Linear:** multi-step triage explained twice, pasted
CLI/MCP sequences, "I always do X then Y", oncall checklist, "can you run the
investigation for…", frustration that docs exist but nobody follows them under pressure.

**Notion-fit signals:** "where is the doc for…", architecture decisions, onboarding
narrative, cross-team context, compliance or design rationale.

When recommending `skill`, include a **workflow sketch** in the output (not a full SKILL.md) — see the output template in Step 5.

---

## Step 3 — Cross-reference coverage

For each candidate, check **both** maps from Steps 1d and 1e (skip whichever the
user omitted).

**Notion**
- Doc exists and is adequate → not a Notion gap for this topic.
- Doc exists but called outdated/wrong → tag `needs-update` (Notion side).
- No doc → tag `missing-notion`.

**Skills**
- Skill exists and covers the workflow → not a skill gap.
- Skill exists but incomplete or unused → tag `needs-skill-update`.
- No skill → tag `missing-skill`.

**Combined status** (for scoring): `missing`, `needs-update`, `covered`.
- `missing` — primary recommended format has no adequate artifact.
- `needs-update` — artifact exists but signals say it's wrong or stale.
- `covered` — drop the candidate unless the gap is the *other* format (e.g. doc
  exists but everyone still does manual triage → recommend `skill` only).

Skip candidates that are fully `covered` on both Notion and skills.

---

## Step 4 — Select top 3

Score each remaining gap on three axes (1–3 each):

| Axis | 1 | 2 | 3 |
|------|---|---|---|
| **Frequency** | Once | 2–3 times | 4+ or multiple sources |
| **Audience reach** | One person | Small sub-team | Full team or oncall |
| **Cost of absence** | Minor inconvenience | Repeated interruptions | Blocks work or incidents |

Pick the 3 highest-scoring gaps. Do not show scores in the output.
Prefer `missing` over `needs-update` when tied.
Prefer a mix of `notion` and `skill` recommendations when scores are close (avoid
three identical format types unless signals demand it).

---

## Step 5 — Present findings

Use the actual scanned channel names and provided Notion URL in the summary line.
Build the "Scanned" sentence dynamically — include only the sources the user enabled.
Omit "Team docs" from the footer if `NOTION_URL` is null.
Omit "Team skills" from the footer if `SKILLS_DIR` is null.

```
*Knowledge Gap Scan — <today's date, e.g. June 1>* 📋

Scanned Slack (#channel-1, #channel-2 + DMs) [and Linear (TEAM, past 30 days)] [and Notion Team Docs] [and team Claude skills].
Here are 3 opportunities worth picking up:

---

*<Topic 1>*
<2–3 sentences: what's missing, why it matters, who gets unblocked>

*Recommended:* <Notion doc | Claude skill | Both — one short sentence why>
*Sources:* <Slack permalinks and/or Linear URLs>

*What it should cover* (if Notion or Both):
• <specific section or question>
• <...>
• <...>

*Skill workflow* (if Claude skill or Both):
• *Triggers:* "<phrase>", "<phrase>"
• *Process:* <numbered steps — what the agent does, which MCP tools or commands, what it outputs; 4–8 steps max>
• *Suggested name:* `<kebab-case-skill-name>` in `<skills-directory>/<name>/`
• *Implement with:* `/skill-writer` or copy an existing skill

---

*<Topic 2>*
...

---

*<Topic 3>*
...

---

Team docs: <Notion URL>
Team skills: `<skills-directory>`
Want to claim one? Reply with Notion or skill 👇
```
