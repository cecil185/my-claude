---
name: model-bakeoff
description: >-
  Serves two separate, gated goals for 2–3 candidate plans of one ticket. (1) ASSESS:
  blindly compare the candidates kept distinct — verify groundedness, lay them side by
  side, isolate where they take different approaches, flag claims to verify — producing
  decision-support, NOT a score or a winner. (2) SYNTHESIZE (optional): after the human
  resolves the forks, assemble a new combined plan from the best parts. Refers to candidates
  ONLY as A/B/C and never learns which model produced which. Does NOT generate the candidates.
  Trigger when user says "model bakeoff", "compare these plans", "compare and contrast these
  outputs", "what's different between these plans", "which of these should I trust", "combine
  the best of these plans", or points at .bakeoff/<TICKET>/*.md candidate files to compare.
model: claude-opus-4-8
effort: high
---

# Model Bakeoff (blind compare-and-contrast)

Compare 2–3 candidate **plans** for the **same** ticket and hand the human what they need to
decide which content is valuable and correct. Do the tedious, reliable work — verifying
references, mapping differences — and stop short of the judgment a human must make.

## Two purposes — keep them separate

1. **Assess (Phases 1–3).** Compare candidates while keeping them **distinct and blind**. Never
   merge them. `A.md`/`B.md`/`C.md` are the assessment record: never edited or overwritten.
2. **Synthesize (Phase 4, optional).** Produce a **new** artifact combining the best parts,
   written to a separate file. Gated on the human first resolving the *Different approaches* forks.

Assessment must complete before synthesis. If the user only wants the comparison, stop after Phase 3.

## What this skill does not do

An AI cannot reliably judge whether a plan is *correct* or *complete* — that needs codebase ground
truth and engineering judgment. So in the assess phases: **no scores, no quality ratings, no
winner.** That would dress an unreliable guess as rigor. Limit yourself to what is reliable:

- **Verify groundedness** — do the cited files/functions/patterns exist? (objective)
- **Diff the plans** — coverage, agreement, divergence. (mapping, not judging)
- **Surface claims to verify** — the assumptions each plan rests on.

## Two hard rules

1. **You know nothing about the source.** Candidates are `A`, `B`, `C` — never a model name. Never
   guess or comment on which model wrote which. If a filename or its contents reveal the source,
   **stop and tell the user** — the set is contaminated. The human holds the label→source key.
2. **Compare only.** The candidates already exist. Never generate or regenerate them.

## File contract

```
.bakeoff/<TICKET>/A.md      # candidates — never edit or overwrite
.bakeoff/<TICKET>/B.md
.bakeoff/<TICKET>/C.md
.bakeoff/<TICKET>/ANALYSIS.md   # written by Phase 3, every run
.bakeoff/<TICKET>/SYNTHESIS.md  # written by Phase 4, optional
```

One file per candidate, named only by an opaque label. If the user points elsewhere, use those —
same rule: nothing in the name or contents may reveal the source.

## Phase 0 — Require a ticket, confirm the set

1. **A Linear ticket is required.** If not provided with the invocation, ask for it and stop —
   without it there is no goal to compare the plans against.
2. **Confirm the set.** Glob `.bakeoff/<TICKET>/*.md`; there must be **≥2** files. If the directory
   is missing or holds fewer, stop and report what was found.
3. Read the **source of truth**: the Linear ticket and the refined Specification the plans came from.

## Phase 1 — Objective groundedness check (facts, not judgment)

**Run as parallel subagents — one per candidate file, `model: 'sonnet'`.** Each check is
independent, and the reading plus many greps is best kept out of the main context; sonnet fits
grep-verification with light classification, reserving Opus for Phases 2 and 4.

Give each subagent only its single candidate. It extracts every concrete reference — file paths,
functions, classes, modules, config keys, existing patterns — and classifies each as **cited as
already existing** (absence = hallucination) or **proposed to be created** (absence is correct).
Only the former counts. Verify via `mcp__fff__grep` / `mcp__fff__find_files`. Each returns **total
references + the actual cited-as-existing references that don't exist** (not just a count).

Collect results in the main loop and present them as facts — the one dimension stated with confidence.

## Phase 2 — Map the comparison (blind)

**Do this in the main loop, NOT in subagents.** Comparison is cross-document and needs all
candidates in one context; and this matrix is the interactive core that Phases 3–4 build on, which
must load the plans into the main loop anyway.

Decompose into the **union of sub-topics/steps** the plans raise (from the candidates plus the
Specification). Build a coverage matrix: per sub-topic, what each candidate says — covered /
differs / silent. **Silence ≠ inferior** — a terse plan may be more focused. Report coverage; never
imply more-coverage-wins.

From the matrix, extract the four things a human needs:

- **Common ground** — what all candidates agree on (likely safe, skim-only).
- **Unique contributions** — what each raises that others miss (A's backfill step, B's rollback
  path). **Guard-rail:** if doing vs. not doing it materially changes the plan, it's a fork —
  promote it to *Different approaches* so it gets adjudicated. Keep only additive "nice to also
  have" items here.
- **Different approaches** — where candidates propose *different ways to do the same thing* (A:
  SQS, B/C: Kafka), plus promoted forks. Phrase each as a question for the human. The heart of the output.
- **Claims to verify** — assertions about the codebase or system behavior to confirm before
  trusting, cross-referenced with Phase 1.

## Phase 3 — Present the assessment (candidates stay distinct)

Produce the assessment in this order — nothing is merged:

1. **Groundedness** — per candidate: references checked, and any cited-as-existing that don't exist.
2. **Coverage matrix** — sub-topic × candidate (covered / differs / silent).
3. **Unique contributions** — per candidate.
4. **Different approaches** — each as a question the human must answer with codebase knowledge
   ("SQS vs Kafka here — which fits the existing consumer?").
5. **Claims to verify** — flagged assumptions, by label.

**Always Write the full assessment to `.bakeoff/<TICKET>/ANALYSIS.md`** and present it in chat.
Every run, no need to ask; overwrite any prior version. A/B/C stay pristine.

Then stop. Never say which plan is "best" or score them. Every observation carries evidence. An
evidence-backed flag a human couldn't quickly see is allowed ("B contradicts the spec's constraint
X — here"); a verdict is not.

Do not begin synthesis. Ask whether the user wants Phase 4, and proceed only once they have
adjudicated the *Different approaches*.

## Phase 4 — Synthesize an optimal output (optional, gated)

Only on request, and only **after** the human resolved the forks. Produces a **new** artifact;
never edits A/B/C.

1. **Gate.** If any fork is unresolved, stop and ask — the skill cannot pick between competing
   approaches itself. Additive unique contributions may be merged freely; forks may not.
2. **Assemble** `.bakeoff/<TICKET>/SYNTHESIS.md` from the common ground, every safe additive unique
   contribution, and the human's chosen option per fork. Keep the strongest wording from whichever
   candidate expressed each part best.
3. **Annotate provenance, blind.** Note each section's origin by label ("backfill step from A;
   queue = Kafka per your call on the B/C fork"). Never name models.
4. **Flag every judgment call** assembly required that the human didn't explicitly give (ordering,
   reconciling overlapping wording, a gap none covered) so they can override. The synthesis is a
   **draft for human review**, not a final plan.

## Out of scope

- **Generation** — the human runs the planning command per source first; a skill can't faithfully
  drive interactive model switching.
- **Other artifacts** — this compares plans. Breakdowns/specs need different comparison shapes.
