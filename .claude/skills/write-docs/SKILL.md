---
name: write-docs
description: Write or improve technical documentation — runbooks, API docs, architecture guides, onboarding pages, READMEs. Use when asked to "document X", "write a runbook for Y", "create a guide for Z", "improve this doc", or "make this readable". Applies Cecil's doc style: summary-first, header-structured, no repetition, follow-up references for depth.
---

# write-docs

Write clear, structured technical documentation. The goal is a doc a reader can triage in 30 seconds: understand scope from the summary, navigate by headers, and drill into subsections only for what they need.

---

## Style rules (non-negotiable)

**Document only what code can't say.** If a fact is obvious from reading the code (function signatures, types, names, control flow), do not document it. Docs exist for intent, tradeoffs, constraints, operational knowledge, and cross-cutting context — not to narrate code.

**No repetition — within or across docs.** State a fact once, in one doc. Never restate the intro in a summary, the summary in a section, or a section in a conclusion. Before adding content, check whether it already lives in another doc; if so, link to it instead.

**Condense ruthlessly.** Every sentence must earn its place. Prefer the shortest form that conveys the fact. Delete any line that restates code, repeats another doc, or hedges around a point already made.

**No padding.** Cut filler openers ("This document covers…", "As described above…"). Start with the thing itself.

**Short sentences over long ones.** If a sentence has two clauses joined by "and", consider splitting it.

**Imperative mood for steps.** "Run `make lint`" not "You should run `make lint`".

**Bold for load-bearing terms**, not decoration. The reader skimming bold words should get the gist.

---

## Document structure

Every doc follows this skeleton — drop sections that don't apply, never add others without good reason:

```
# Title

> **Summary** — 2–4 sentences. What this is, who it's for, when to use it.
> Mention follow-up sections by name for deeper context.

## Prerequisites / Context  ← include only if reader truly needs setup before proceeding

## <Core section 1>
## <Core section 2>
## ...

## Troubleshooting  ← include only if failure modes are non-obvious

## Reference  ← include only if there are tables, enums, config keys that don't belong inline
```

**The summary is mandatory.** It is the doc's contract with the reader: this is what I cover, this is what I don't. It should name 1–2 sections the reader can skip to if they already have context.

---

## Section rules

**One idea per section.** If a section grows past ~6–8 bullets or ~200 words, split it or move depth to a subsection.

**Use tables for:** comparisons, config keys + types + defaults, error codes + causes, service maps.

**Use numbered lists for:** ordered steps where sequence matters.

**Use bullet lists for:** unordered options, characteristics, gotchas.

**Use code blocks for:** every command, config snippet, file path, env var — even single-word ones.

**Cross-reference, don't repeat.** If detail lives in another section, write "See [Section Name]" and stop. Don't inline the same explanation twice.

---

## Process

1. **Identify the doc type** — runbook, API reference, architecture guide, onboarding, README, design doc. Each has a natural skeleton (see below).

2. **Identify the audience and entry point.** What do they already know? What question brings them here? Write for that reader, not a hypothetical beginner.

3. **Draft the summary first.** If you can't summarize in 3 sentences what the doc covers, the scope is unclear — clarify before continuing.

4. **Fill sections bottom-up** — write the details, then write the section intro to frame them. Never write the intro first.

5. **Audit for repetition.** Each factual claim should appear exactly once across the entire doc set. Cross-reference instead of restating. If another doc already covers it, link and stop.

6. **Audit against the code.** Strip anything a reader could learn by opening the file. Keep only the why, the constraints, and the operational knowledge.

7. **Cut.** If a sentence doesn't add information the reader needs, delete it. When in doubt, cut.

---

## Doc type skeletons

### Runbook

```
# <Action> — <System>

> **Summary** — When to run this, what it does, risk level. See [Rollback] if something goes wrong.

## Prerequisites
## Steps
## Validation
## Rollback
```

### Architecture / design doc

```
# <System or Feature> — Architecture

> **Summary** — What problem this solves, the key tradeoffs, what's out of scope. See [Data Flow] for the technical detail.

## Problem
## Design
## Data Flow  (ASCII diagram + prose)
## Alternatives Considered
## Open Questions
## Out of Scope
```

### API / interface reference

```
# <API Name>

> **Summary** — What this API does, auth model, base URL. See [Endpoints] for the full list.

## Authentication
## Endpoints
## Error codes
## Examples
```

### Onboarding / README

```
# <Project Name>

> **Summary** — What this repo does, who owns it, how to get started. See [Local Setup] to run it.

## Local Setup
## Architecture (link or one-paragraph ASCII)
## Development workflow
## Deployment
## Contact / on-call
```

---

## Tone

Match the doc's operational register:
- **Runbook / step-by-step:** Imperative, precise, no ambiguity. Every step is verifiable.
- **Architecture doc:** Analytical. Acknowledge tradeoffs. "We chose X because Y; the cost is Z."
- **README / onboarding:** Direct and welcoming. One paragraph of context, then get them running.
- **Reference tables:** No prose. Keys, types, values, defaults. Done.

Across all types: no hedging ("might", "possibly", "generally speaking"), no thought-leader posturing, no "as you can see".

---

## Output

Deliver the doc as markdown. No preamble, no trailing "let me know if you'd like changes." The doc is the deliverable.

If the request is ambiguous (unclear audience, unclear scope), ask one clarifying question — not a list. Then write.
