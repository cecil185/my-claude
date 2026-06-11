---
name: model-bakeoff
description: >-
  Blindly compares 2–3 candidate plans for one ticket and produces decision-support for
  a human — NOT a score or a winner. Verifies what is objectively checkable (groundedness),
  lays the plans side by side, isolates where they diverge (the real decision points), and
  flags claims to verify. Refers to candidates ONLY as A/B/C and never learns which model
  produced which; the human holds that mapping and makes the final call on correctness and
  value. Does NOT generate the candidates.
when_to_use: >-
  Trigger when the user says "model bakeoff", "compare these plans", "compare and contrast
  these outputs", "what's different between these plans", "which of these should I trust",
  or points at a set of .bakeoff/<TICKET>/*.md candidate files to compare.
model: claude-opus-4-8
effort: high
---

# Model Bakeoff (blind compare-and-contrast)

Compare 2–3 candidate **plans** for the **same** ticket and hand the human what they need
to decide which content is valuable and correct. The skill does the tedious, reliable work
— verifying references and mapping differences across three documents — and stops short of
the judgment a human must make.

## What this skill does and does NOT do

An AI cannot reliably judge whether a plan is *correct* or *complete* — that needs codebase
ground truth and engineering judgment. So this skill **does not score plans, rate quality,
or pick a winner.** Doing so would dress an unreliable guess as rigor.

It limits itself to what an AI does reliably:

- **Verify groundedness** — do the files/functions/patterns a plan cites actually exist? (objective, checkable)
- **Diff the plans** — what each covers, where they agree, where they diverge. (mapping, not judging)
- **Surface claims to verify** — the assumptions each plan rests on, flagged for the human.

The correctness and value call is the human's. The skill's output is decision-support.

## Two hard rules

1. **You know nothing about the source.** Candidates are `A`, `B`, `C` — never a model name.
   Do not guess or comment on which model wrote which. If a filename or contents reveal the
   source, **stop and tell the user** — the set is contaminated. The human holds the
   label→source key; the skill never sees it. (Blinding keeps the human's later read free of
   reputation bias too.)
2. **Compare only.** The candidates already exist. Never generate or regenerate them.

## File contract

```
.bakeoff/<TICKET>/A.md
.bakeoff/<TICKET>/B.md
.bakeoff/<TICKET>/C.md
```

One file per candidate, named only by an opaque label. If the user points elsewhere, use
those — same rule: nothing in the name or contents may reveal the source.

## Phase 0 — Require a ticket, then confirm the set exists

1. **A Linear ticket is required.** If the user did not provide one with the invocation,
   **ask for it and stop** until they do — without the ticket there is no goal to compare
   the plans against.
2. **Confirm the candidate set exists.** Glob `.bakeoff/<TICKET>/*.md`. There must be **≥2
   `.md` files**. If the directory is missing or holds fewer than two, **stop and tell the
   user** what was found (e.g. "no `.bakeoff/DP-123/` directory" or "only one candidate") —
   there is nothing to compare.
3. Read the **source of truth**: the Linear ticket and the refined Specification the plans
   were written from. You need the goal to map the plans against it.

## Phase 1 — Objective groundedness check (facts, not judgment)

**Run this as parallel subagents — one per candidate file.** Each check is independent and
the work (reading a full plan, many greps) is best kept out of the main context. Dispatch
one Agent per `*.md`, each given only its single candidate. Each subagent extracts every
concrete reference — file paths, functions, classes, modules, config keys, existing
patterns — verifies each EXISTS via `mcp__fff__grep` / `mcp__fff__find_files`, and returns
**total references + a list of any that don't exist** (the actual bad reference, not just a
count). Collect the per-candidate results in the main loop. Present them as facts — this is
the one dimension the skill states with confidence.

## Phase 2 — Map the comparison (blind)

**Do this in the main loop — NOT in subagents.** Comparison is cross-document: it requires
all candidates in the same context window at once. A per-candidate subagent can't diff what
it can't see.

Decompose the work into the **union of sub-topics/steps** the plans raise (derive from the
candidates plus the Specification). Build a coverage matrix: for each sub-topic, what does
each candidate say — covered / differs / silent.

From the matrix, extract the four things a human actually needs:

- **Common ground** — what all candidates agree on (likely safe, skim-only).
- **Unique contributions** — what each candidate raises that the others miss (A's backfill
  step, B's rollback path). The value often hides here. **Guard-rail:** if a unique
  contribution is actually a meaningful fork — i.e. doing it vs. not doing it materially
  changes the plan — promote it to **Different approaches** so it gets adjudicated, not
  skimmed. Keep here only the additive "nice to also have" items.
- **Different approaches** — where candidates propose *different ways to do the same thing*
  (A: SQS, B/C: Kafka), plus any promoted forks from above. Phrase each as a question for
  the human to adjudicate. These are the heart of the output.
- **Claims to verify** — assertions about the codebase or system behavior the human should
  confirm before trusting, cross-referenced with Phase 1 groundedness.

## Phase 3 — Present decision-support (no winner, no scores)

Output, in this order:

1. **Groundedness** — per candidate, references checked and any that don't exist. Facts.
2. **Coverage matrix** — sub-topic × candidate (covered / differs / silent).
3. **Unique contributions** — per candidate, what only it raised.
4. **Different approaches** — the divergences, each as a question the human must answer with
   codebase knowledge ("SQS vs Kafka here — which fits the existing consumer?").
5. **Claims to verify** — flagged assumptions, by label.

Then stop. Do **not** say which plan is "best." All your observations must have
evidence. You may suggest cherry-picking the best parts of output if that adds real value.
Human makes the final decision about which original output was the best and what combination of outputs to proceed with.

## Blinded note for the user's own log

Emit a copy-pasteable blinded block the user can file against their own private key (the skill never sees the key):

```
Ticket: <TICKET>   Artifact: plan   Date: <session or user-supplied>
A: refs_ok=__/__  unique_contribs=__  in_different_approaches=__
B: ...
C: ...
(Human note: which labels' content I ended up using = ____)
```

The data point the user records is *which content they chose*, judged with their own
codebase knowledge — not an AI score.

## Out of scope

- **Generation** — the human runs the planning command per source first; a skill can't
  faithfully drive interactive model switching.
- **Other artifacts** — this compares plans. Breakdowns/specs need different comparison
  shapes and aren't handled here yet.
