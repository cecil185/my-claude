---
name: ledger-mr-review
description: Runs an adversarial Merge Request / Pull Request code review using the Gemini CLI as an independent reviewer model, and appends the structured review to <repo>/code-review.md as an additive-only debate ledger.
---

# Ledger MR Review Skill (`ledger-mr-review`)

## Purpose
The `ledger-mr-review` skill gets a genuine second opinion on Git changes, Merge Requests (MRs), or Pull Requests (PRs) by delegating the adversarial ("red-team") critique to **Gemini**, via the `gemini` CLI, rather than having Claude review its own work. Gemini scrutinizes changes from a critical perspective — assuming bugs, race conditions, edge-case failures, unhandled nulls, and performance regressions exist until proven otherwise.

All reviews are recorded into an **additive-only ledger file** (`<repo>/code-review.md`) to facilitate multi-model asynchronous debate with the companion `response-to-feedback` skill.

## Full Debate Workflow
1. Make code changes as usual.
2. Run `/ledger-mr-review` (this skill) — appends Gemini's adversarial review to `<repo>/code-review.md`.
3. Run `/response-to-feedback` — Claude reads Gemini's entry and appends a defense/concession/fix entry.
4. Apply any fixes Claude conceded to. Re-run `/ledger-mr-review` for another round if needed.
5. Stop once a Gemini review entry has no remaining CRITICAL/MAJOR items.

---

## Key Principles & Execution Workflow

### 0. Delegate the Critique to Gemini (do not self-review)
1. Confirm the target repo/worktree (per CLAUDE.md worktree discipline) and get the diff to review, e.g.:
   `git diff main...HEAD` (or the relevant base branch/commit range).
2. Run Gemini headlessly, piping the diff in on stdin and passing the adversarial review prompt via `-p`. Use `--approval-mode plan` so Gemini runs read-only (no edits):
   ```
   git diff main...HEAD | gemini -p "You are an adversarial code reviewer. Assume bugs, race conditions, edge-case failures, unhandled nulls, missing validation, and performance regressions exist until proven otherwise in this diff. For each issue give: severity (CRITICAL/MAJOR/MINOR), file:line, failure mode, and what would disprove it. Also list untested edge cases. Output plain text, no code execution." --approval-mode plan -o text
   ```
3. Capture Gemini's raw output as-is — this is the independent review content. Do not edit or soften Gemini's findings when transcribing them into the ledger; only reformat into the structure below.
4. If the diff is large, note in the ledger entry which files/hunks were included (Gemini has its own context limits) rather than silently truncating.

### 1. Adversarial Mindset (what Gemini is prompted to apply)
* **Challenge Assumptions**: Question boundary conditions, missing validation, silent failure modes, implicit type conversions, and resource leaks.
* **Inspect Scalability & Performance**: Identify missing database/partition indexes, unbounded in-memory lists, N+1 query patterns, and lock contention.
* **Verify Test Robustness**: Highlight missing negative test cases, mocked-out assertions, and untested error paths.
* **Zero False Security**: Never accept superficial symptom fixes or swallowed exceptions.

### 2. Additive-Only Ledger Discipline (`code-review.md`)
* **File Path**: Write to `<repo>/code-review.md` relative to the target repository root (e.g. `ingestion/code-review.md`).
* **Additive Only**: **NEVER** overwrite, modify, or truncate existing contents in `code-review.md`. If the file exists, read it first and append new entries to the bottom. If it does not exist, create it.
* **Ledger Entries**: Each review entry represents a discrete turn in the code review and debate lifecycle.

---

## Output Format Specification

Appended entries in `<repo>/code-review.md` MUST follow this exact Markdown structure:

```markdown
---
## [Review Entry] - <YYYY-MM-DD HH:MM:SS TZ>
**Model / Role**: Gemini (Adversarial Reviewer, via `gemini` CLI)  
**Target Repository**: `<repo>`  
**Branch / Ref**: `<branch_or_commit>`  
**Review Type**: Adversarial Code Review  

### 1. Executive Adversarial Thesis
A concise high-level critique highlighting the primary risks, flawed architectural assumptions, or critical oversights in this change set.

### 2. Critical Findings & Vulnerability Matrix

#### [CRITICAL | MAJOR | MINOR] Issue Title
* **Location**: [`<file_path>#L<line_start>-L<line_end>`](file:///<absolute_path>#L<line_start>-L<line_end>)
* **Attack Vector / Failure Mode**: Detailed explanation of how this code will fail in production, under load, or with edge-case inputs.
* **Evidence / Logic Trace**:
  ```python
  # Code snippet demonstrating the failure or flaw
  ```
* **Required Defense / Refutation Criteria**: What specific proof or code change is required from an opposing reviewer or author to disprove this vulnerability?

### 3. Verification & Test Coverage Deficits
* Untested edge cases, unverified error paths, or insufficient assertion logic.

### 4. Open Questions for Secondary Reviewer
- [ ] Explicit challenge item 1 for the opposing model to assess or refute.
- [ ] Explicit challenge item 2.
```

---

## Usage Guide
1. Confirm the target repo/worktree and diff range to review.
2. Run the `gemini` CLI headlessly (see Step 0) to obtain the independent adversarial critique — do not write the critique yourself.
3. Check if `<repo>/code-review.md` exists. Read its contents.
4. Transcribe Gemini's findings into the ledger entry format and append to `<repo>/code-review.md`.
5. Tell the user the review is ready and that `/response-to-feedback` will address it.
