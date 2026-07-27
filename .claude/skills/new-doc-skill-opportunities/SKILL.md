---
name: new-doc-skill-opportunities
description: >-
  Scans Slack, DMs, and Linear to identify knowledge gaps for any team — missing Notion docs or
  team Claude skills — and surfaces the top 3 opportunities. Each recommends Notion vs skill (or
  both), with links, a content outline, and a skill workflow sketch when a skill is the better fit.
  Does not write docs or skills. Trigger when user says "find doc gaps", "what needs documenting",
  "doc scan", "doc opportunity scan", "skill gap scan", "identify documentation opportunities",
  "what should we document", "doc audit", "team skill opportunities", or "post doc gaps to Slack".
model: sonnet
effort: medium
---

# Knowledge Gap Scanner

Identify the top 3 knowledge opportunities for a team. Gather signals from Slack, DMs, and Linear,
cross-reference existing Notion docs **and** team Claude skills, then surface the most impactful
gaps — each with a recommendation: **Notion doc**, **Claude skill**, or **both**.

---

## Step 0 — Gather team configuration

Ask for all four in a single message, then wait for the reply:

> To run the scan, I need a few details:
> 1. **Slack channel(s)** — which to scan (e.g. `#team-eng-data-platform`), comma-separated
> 2. **Notion root page URL** — your team's docs root (blank to skip Notion)
> 3. **Linear team key** — e.g. `DP`, `ENG` (blank to skip Linear)
> 4. **Skills directory path** — where team Claude skills live (blank to skip)

Store as `CHANNELS` (list), `NOTION_URL`, `LINEAR_KEY`, `SKILLS_DIR` (each or null).

---

## Step 1 — Gather signals in parallel

Compute the 30-days-ago date as `YYYY-MM-DD` at runtime; never hard-code it. Skip any source the
user left blank.

**1a. Team channels** — per channel, `mcp__claude_ai_Slack__slack_search_public_and_private` with
`query: "in:<channel> after:<30d-ago>"`. Look for: repeated questions, "how do I…", "where is…",
process confusion, the same thing explained twice, "reminder"/"heads up, just learned…", "can
Claude…", "is there a skill for…", runbook steps pasted into threads, ad hoc oncall playbooks.

**1b. Your DMs** — same tool with `query: "to:me after:<30d-ago>"`, `channel_types: "im,mpim"`.
Look for: questions you answered manually, "how does X work", "do we have docs on…". Multi-step
walkthroughs you gave more than once are strong **skill** candidates.

**1c. Linear tickets** — `mcp__claude_ai_Linear_HTTP__list_issues` with `teamKey: LINEAR_KEY`,
`createdAt: "-P30D"`, `limit: 100`. Look for: tickets mentioning "document", "runbook", "wiki",
"onboarding", "how to", "skill", "Claude", "agent"; unusually long descriptions explaining existing
behavior (no doc existed); repeated SPIKEs on one topic; chores automating a recurring workflow.

**1d. Notion coverage map** — `mcp__claude_ai_Notion__notion-fetch` on `NOTION_URL`; extract the
list of existing pages/sections.

**1e. Skills coverage map** — `find <SKILLS_DIR> -iname 'SKILL.md'`, then read each file's `name`
and `description`. Use it to avoid recommending skills that already exist.

---

## Step 2 — Extract gap signals

Per signal, extract a candidate gap with: **Topic** (what's missing, e.g. "deploy rollback
runbook"), **Signal type** (`repeated-question`, `dm-explanation`, `linear-ticket`, `spike-topic`,
`onboarding-friction`, `manual-workflow`, `agent-request`), **Frequency** (times surfaced across
sources), **Audience** (new hire, oncall, data consumer), **Source links** (Slack permalinks, Linear
URLs), **Urgency hint** (explicit "we need to write this up"), and **Recommended format**.

Deduplicate across sources — the same topic in a DM and a channel counts once, with higher frequency.

### Notion vs Claude skill

Assign **one** primary recommendation (`notion` or `skill`). Use `both` only when reference material
and an executable workflow are clearly separate needs.

| Prefer **Notion doc** | Prefer **Claude skill** | Prefer **both** |
|---|---|---|
| Stable facts, architecture, policies | Repeatable process with tool calls (MCP, AWS, Datadog, git) | Long reference + a workflow run often |
| Read by humans without Claude (stakeholders, audit) | Same steps every time; benefits from live repo/infra context | Onboarding doc + day-one agent helper |
| Browsable sections, diagrams, glossary | Triggered by natural language in chat | Runbook in Notion; skill runs the checks and links to it |
| Changes rarely; linked from many places | Secrets stay in agent env; authenticated MCP queries | |

**Skill-fit signals:** multi-step triage explained twice, pasted CLI/MCP sequences, "I always do X
then Y", oncall checklists, "can you run the investigation for…", frustration that docs exist but
nobody follows them under pressure.

**Notion-fit signals:** "where is the doc for…", architecture decisions, onboarding narrative,
cross-team context, compliance or design rationale.

---

## Step 3 — Cross-reference coverage

Check each candidate against both maps (skip whichever the user omitted):

- **Notion:** adequate doc exists → not a Notion gap. Exists but called outdated/wrong →
  `needs-update`. None → `missing-notion`.
- **Skills:** skill covers the workflow → not a skill gap. Exists but incomplete or unused →
  `needs-skill-update`. None → `missing-skill`.

Combined status for scoring: `missing` (primary recommended format has no adequate artifact),
`needs-update` (exists but signals say wrong or stale), or `covered`. Drop fully-`covered`
candidates — unless the gap is the *other* format (doc exists but everyone still does manual triage
→ recommend `skill` only).

---

## Step 4 — Select top 3

Score each remaining gap 1–3 per axis:

| Axis | 1 | 2 | 3 |
|---|---|---|---|
| **Frequency** | Once | 2–3 times | 4+ or multiple sources |
| **Audience reach** | One person | Small sub-team | Full team or oncall |
| **Cost of absence** | Minor inconvenience | Repeated interruptions | Blocks work or incidents |

Take the 3 highest. Never show scores. Prefer `missing` over `needs-update` when tied, and prefer a
mix of `notion` and `skill` recommendations when scores are close.

---

## Step 5 — Present findings

Build the "Scanned" sentence dynamically from only the enabled sources; omit the "Team docs" footer
line if `NOTION_URL` is null and "Team skills" if `SKILLS_DIR` is null.

```
*Knowledge Gap Scan — <today's date, e.g. June 1>* 📋

Scanned Slack (#channel-1, #channel-2 + DMs) [and Linear (TEAM, past 30 days)] [and Notion Team Docs] [and team Claude skills].
Here are 3 opportunities worth picking up:

---

*<Topic>*
<2–3 sentences: what's missing, why it matters, who gets unblocked>

*Recommended:* <Notion doc | Claude skill | Both — one short sentence why>
*Sources:* <Slack permalinks and/or Linear URLs>

*What it should cover* (if Notion or Both):
• <specific section or question>  ← 3 bullets

*Skill workflow* (if Claude skill or Both):
• *Triggers:* "<phrase>", "<phrase>"
• *Process:* <numbered steps — what the agent does, which MCP tools or commands, what it outputs; 4–8 steps max>
• *Suggested name:* `<kebab-case-skill-name>` in `<skills-directory>/<name>/`
• *Implement with:* `/skill-writer` or copy an existing skill

---

<repeat for topics 2 and 3, separated by --->

Team docs: <Notion URL>
Team skills: `<skills-directory>`
Want to claim one? Reply with Notion or skill 👇
```
