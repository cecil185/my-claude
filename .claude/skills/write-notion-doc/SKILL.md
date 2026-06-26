---
name: write-notion-doc
description: >-
  Write or improve a Notion doc — runbooks, spike specs, architecture notes,
  onboarding pages, or general team docs. First drafts are 300 words: scaffold
  headers and summaries, drill in on follow-up passes. Trigger when user says
  "write a Notion doc", "draft this for Notion", "create a page for X", or
  "document X for the team".
when_to_use: >-
  Trigger for any Notion page — runbook, design doc, spike spec, team reference,
  onboarding.
---

# write-notion-doc

> **Word limit (first draft): 300 words.** Scaffold headers and section summaries first — drill into content on follow-up passes.

Always read and apply **[write-style](../write-style/SKILL.md)** first for Cecil's voice. Also read **[examples.md](./examples.md)** for real Notion doc patterns before drafting.

**First draft target: 300 words.** Scaffold the structure — title, summary callout, section headers, key bullets — then stop. Drill into subsections on follow-up passes once the shape is confirmed.

---

## Clarify Before Writing

If not already clear, ask:
- What type of doc? (runbook, spike spec, architecture note, onboarding, general reference)
- Who's the audience and what question brings them here?

One question. If context is obvious, skip and write.

---

## Notion-Specific Structure

Every doc follows this skeleton — drop sections that don't apply:

```
# Title

> Summary callout — 2–4 sentences. What this is, who it's for, when to use it.
> Name 1–2 sections the reader can skip to if they have context.

## Prerequisites / Context   ← only if reader needs setup before proceeding

## <Core section 1>
## <Core section 2>
## ...

## Troubleshooting   ← only if failure modes are non-obvious

## Reference   ← tables, config keys, enums that don't belong inline
```

The summary callout is mandatory. It's the doc's contract with the reader.

---

## Doc Type Skeletons

### Runbook
```
# <Action> — <System>
> Summary — When to run this, what it does, risk level.

## Prerequisites
## Steps
## Validation
## Rollback
```

### Spike Spec / Design Doc
```
# <Feature> — Spike

> Summary — Problem, what we're exploring, what's out of scope.

## Current State
## What We Want
## Automation Opportunities
## Open Questions  (table: Question | Owner | Status)
## Success Criteria  (checkboxes)
## Out of Scope
```

### Architecture Note
```
# <System> — Architecture

> Summary — What problem this solves, key tradeoffs, what's out of scope.

## Problem
## Design
## Data Flow  (ASCII diagram + prose)
## Alternatives Considered
## Open Questions
## Out of Scope
```

### Onboarding / Team Reference
```
# <Topic>

> Summary — What this covers, who it's for, how to use it.

## Overview
## <Core sections>
## Contact / Owner
```

---

## Style Rules

- **Lead with the problem or purpose** — never with background the reader already has
- **One idea per section** — if a section grows past ~6–8 bullets or ~200 words, split it
- **Tables for:** comparisons, config keys + types + defaults, open questions, service maps
- **Numbered lists for:** ordered steps where sequence matters
- **Bullet lists for:** unordered options, characteristics, gotchas
- **Code blocks for:** every command, config snippet, file path, env var
- **Cross-reference, don't repeat** — if detail lives elsewhere, link to it and stop
- **No filler openers** — cut "This document covers…", "As described above…"
- **Imperative mood for steps** — "Run `make lint`" not "You should run `make lint`"

---

## Output

Deliver the doc as markdown. No preamble, no trailing "let me know if you'd like changes."

After the first draft, offer: "Want to drill into any section, or does the structure look right?"
