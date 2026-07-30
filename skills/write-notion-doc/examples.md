# Notion Docs — Real Examples

Source: Cecil Ash's docs in the Data Platform Notion workspace. Primary reference: DP-731 Spike — Data Pipeline Architecture Review.

---

## Example 1 — Spike / Architecture Review Doc

**Title:** `🔎 DP-731 Spike — Data Pipeline Architecture Review`
**Location:** Architecture & Design Docs › Data Platform

### Opening / framing
```
**Linear:** DP-731 — SPIKE: Data Pipeline Architecture Review
**Project:** Data Platform Q2 Architecture Analysis & Design
**Owner:** Laszlo Horanszky
**Status:** Draft — in progress
**Timebox:** 5 calendar days (per AC)

> Working doc. Each sub-issue below is a separate exploration point and will be filled in one-by-one. Recommendations and new project asks roll up at the bottom once the team has reviewed.
```

### Goal section
```
## Goal
Perform a critical, end-to-end architecture review of the AMS vendor ingestion + lakehouse pipeline for scaling to 200+ vendors with high reliability and maintainability.
```

**What to note:**
- Metadata block at top (Linear link, owner, status, timebox) — not a separate section
- Blockquote for working-doc disclaimers / scope notes
- Goal = one sentence, problem-first
- Section header is `## Goal`, not `## Overview` or `## Introduction`

---

## Example 2 — Structural pattern from onboarding doc

**Title:** `AMS Software Engineer Onboarding (EM Playbook)`

Structure observed:
```
> This is the engineering manager checklist + schedule for onboarding software engineers joining Smartabase/AMS. Use it to drive access provisioning, meetings, and a 30/60/90 ramp. Source docs to share with the new hire are linked inline.

## Before Day 1
## Week 1
## 30-Day Check-in
## 60-Day Check-in
## 90-Day Check-in
```

**What to note:**
- Opening callout states who the doc is FOR and how to USE it (not just what it covers)
- Sections follow the natural chronological flow of the work — no artificial "Overview" section
- No trailing "Contact / Questions" filler section

---

## Pattern Summary

### What Cecil's Notion docs look like

**Opening:**
- Metadata block (owner, status, ticket link) at the very top when relevant
- Blockquote summary/disclaimer immediately after — 1–3 sentences on scope and audience
- Jumps into first section immediately after

**Sections:**
- `## Goal` or `## Problem` — not `## Overview` or `## Introduction`
- Sections named after the content, not generic labels
- Tables for: config, open questions (Question | Owner | Status), comparison matrices
- ASCII diagrams for system flows — no screenshots of whiteboards
- Checklists (`- [ ]`) for sequential steps, not prose instructions
- Code blocks for every command, path, or env var

**Tone:**
- "Working doc" and status noted early — doesn't pretend to be finished when it isn't
- Opinions stated plainly: "Riskiest part about launching this MVP will be..."
- Open questions surfaced explicitly, not buried

**What's absent:**
- No "This document covers..." opener
- No "As described above" cross-references
- No "In conclusion" or summary at the end
- No generic section names like "Background" or "Context"

---

## First Draft Shape (300 words)

A 300-word Notion first draft looks like:

```
# Title

> [2–3 sentence summary: what this is, who it's for, what they'll get from it]

## [Core Section 1]
[4–6 bullets or 2–3 short paragraphs]

## [Core Section 2]
[Table or bullets]

## Open Questions
| Question | Owner | Status |
|---|---|---|
| [question] | [name] | Open |

## Out of Scope
- [item]
- [item]
```

Then stop. Structure first, content second.
