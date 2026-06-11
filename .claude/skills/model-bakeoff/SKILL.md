---
name: model-bakeoff
description: >-
  Serves two separate, gated goals for 2–3 candidate plans of one ticket. (1) ASSESS:
  blindly compare the candidates kept distinct — verify groundedness, lay them side by
  side, isolate where they take different approaches, flag claims to verify — producing
  decision-support, NOT a score or a winner. (2) SYNTHESIZE (optional): after the human
  resolves the forks, assemble a new combined plan from the best parts. Refers to candidates
  ONLY as A/B/C and never learns which model produced which. Does NOT generate the candidates.
when_to_use: >-
  Trigger when the user says "model bakeoff", "compare these plans", "compare and contrast
  these outputs", "what's different between these plans", "which of these should I trust",
  "combine the best of these plans", or points at a set of .bakeoff/<TICKET>/*.md candidate
  files to compare.
model: claude-opus-4-8
effort: high
---

# Model Bakeoff (blind compare-and-contrast)

Compare 2–3 candidate **plans** for the **same** ticket and hand the human what they need
to decide which content is valuable and correct. The skill does the tedious, reliable work
— verifying references and mapping differences across three documents — and stops short of
the judgment a human must make.

## Two purposes — keep them separate

This skill serves two distinct goals. Do not blur them; they have opposite operations and
run in separate, gated phases.

1. **Assess (Phases 1–3).** Compare the candidates while keeping them **distinct and
   blind**. Never merge them. The originals (`A.md`/`B.md`/`C.md`) are the assessment record
   and must stay pristine — never edited or overwritten.
2. **Synthesize (Phase 4, optional).** Produce a **new** artifact combining the best parts
   of the candidates. This is generative authoring, written to a separate file, and is
   gated on the human first resolving the *Different approaches* forks (see Phase 4).

Assessment must complete before synthesis begins. If the user only wants the comparison,
stop after Phase 3.

## What this skill does and does NOT do

An AI cannot reliably judge whether a plan is *correct* or *complete* — that needs codebase
ground truth and engineering judgment. So in the **assess** phases this skill **does not
score plans, rate quality, or pick a winner.** Doing so would dress an unreliable guess as
rigor.

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

**Never edit or overwrite the candidate files.** They are the assessment record. The skill
writes two of its own files, never touching A/B/C:

- `.bakeoff/<TICKET>/ANALYSIS.md` — the Phase 3 assessment (written every run; see Phase 3).
- `.bakeoff/<TICKET>/SYNTHESIS.md` — the optional Phase 4 synthesis.

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

**Run this as parallel subagents — one per candidate file, at `model: 'sonnet'`.** Each
check is independent and the work (reading a full plan, many greps) is best kept out of the
main context. Sonnet is the right tier here — it's grep-verification plus light
classification, not cross-document reasoning, so a cheaper/faster model fits the parallel
fan-out; reserve Opus for the comparison and synthesis in Phases 2 and 4. Dispatch one
Agent per `*.md`, each given only its single candidate. Each subagent extracts every
concrete reference — file paths, functions, classes, modules, config keys, existing
patterns — and classifies each: is it cited as **already existing** (so its absence is a
hallucination) or **proposed to be created** by the plan (so its absence is correct, not a
fault)? Only the former counts. Verify existing-cited references via `mcp__fff__grep` /
`mcp__fff__find_files`, and return **total references + a list of any cited-as-existing that
don't actually exist** (the actual bad reference, not just a count). Collect the
per-candidate results in the main loop. Present them as facts — this is the one dimension
the skill states with confidence.

## Phase 2 — Map the comparison (blind)

**Do this in the main loop — NOT in subagents.** Two reasons: (1) comparison is
cross-document — it needs all candidates in one context window, so a per-candidate subagent
can't diff what it can't see; (2) even a single subagent holding all three isn't worth it —
this matrix is the interactive core that Phase 3 presents and Phases 3–4 build on (fork
adjudication, synthesis), and Phase 4 must load the plans into the main loop anyway, so
isolating Phase 2 saves no real context while adding a round-trip.

Decompose the work into the **union of sub-topics/steps** the plans raise (derive from the
candidates plus the Specification). Build a coverage matrix: for each sub-topic, what does
each candidate say — covered / differs / silent. **Silence ≠ inferior** — a terse plan that
omits a sub-topic may be more focused, not worse. Report coverage; never imply
more-coverage-wins.

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

## Phase 3 — Present the assessment (Purpose 1: keep candidates distinct)

Produce the assessment in this order — candidates stay distinct, nothing is merged:

1. **Groundedness** — per candidate, references checked and any cited-as-existing that don't
   exist. Facts.
2. **Coverage matrix** — sub-topic × candidate (covered / differs / silent).
3. **Unique contributions** — per candidate, what only it raised.
4. **Different approaches** — the divergences, each as a question the human must answer with
   codebase knowledge ("SQS vs Kafka here — which fits the existing consumer?").
5. **Claims to verify** — flagged assumptions, by label.

**Always write the full assessment to `.bakeoff/<TICKET>/ANALYSIS.md`** (using the Write
tool), AND present it in the chat response. This happens on every run — no need to ask.
`ANALYSIS.md` contains the five sections above plus the blinded-log block; it is the skill's
durable output and must leave A/B/C pristine. If `ANALYSIS.md` already exists from a prior
run, overwrite it with the current assessment.

Then stop. Do **not** say which plan is "best" or score them. Every observation must carry
evidence. A flagged observation a human couldn't quickly see is allowed ("B contradicts the
spec's constraint X — here") as long as it's evidence-backed, not a verdict. The human
decides which candidate's content is valuable.

Do not begin synthesis here. Ask whether the user wants Phase 4 — and only proceed once
they've adjudicated the Different approaches (Purpose 2 depends on those answers).

## Phase 4 — Synthesize an optimal output (Purpose 2: optional, gated)

Only on request, and only **after** the human has resolved the *Different approaches* forks.
This produces a **new** artifact; it never edits A/B/C.

1. **Gate.** If any fork is unresolved, stop and ask — the skill cannot pick between
   competing approaches itself (that needs the codebase judgment Phase 3 deferred to the
   human). Additive unique contributions may be merged freely; forks may not.
2. **Assemble** `.bakeoff/<TICKET>/SYNTHESIS.md` by combining: the common ground, every
   safe additive unique contribution, and — for each fork — the option the human chose.
   Keep the strongest wording from whichever candidate expressed each part best.
3. **Annotate provenance, blind.** For each assembled section note where it came from by
   label ("backfill step from A; queue = Kafka per your call on the B/C fork"). Stay blind —
   never name models.
4. **Flag every judgment call you made.** Where assembly required a choice the human didn't
   explicitly give (ordering, reconciling overlapping wording, a gap none covered), mark it
   so they can override. The synthesis is a **draft for human review**, not a final plan.

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
