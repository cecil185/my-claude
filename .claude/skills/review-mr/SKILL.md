---
name: review-mr
description: >-
  Review a GitLab merge request and surface the most important issues.
  Use when asked to review an MR, critique a diff, or look at a merge request.
model: claude-opus-4-6
effort: high
---

# Review Merge Request

Produce a focused, high-signal critique of a merge request. No noise.
Do not flag anything you haven't verified by reading the actual code.
Before claiming something is missing or wrong, **search the source files** to
confirm — do not assume. If you cannot verify a concern, label it `[UNVERIFIED]`
and state what you'd need to check.

## Before writing feedback

When reviewing an MR, **before writing any feedback**:

1. **List the files you need to read** — Start by listing every changed file you will read (from the MR diff, `git diff` stat, or equivalent).
2. **Read every changed file in full** — Not only the diff hunks; read each file’s complete current contents so imports, callers, and surrounding logic are understood.
3. **Cite exact locations** — For any issue, include the exact file path and line number.
4. **Verify before claiming gaps** — Do not claim something is missing or duplicated unless you have verified it by reading the source (the full file, not assumptions from the diff alone).

## Instructions
1. Follow **Before writing feedback**: list changed files, then read each changed file in full, then use the diff to see what changed vs the base.
2. For every issue found, cite the exact file path and line number.
3. Do NOT claim something is missing or duplicated without reading the actual source to verify.
4. Rank findings by severity: critical > major > minor > nit
5. Format as a structured table with columns: Severity | File | Line | Issue | Suggestion
6. If no issues found, say so — do not invent concerns

## Gather the Diff

Use one of these approaches depending on what the user provides:

| Input | How to get the diff |
|---|---|
| MR URL | `mcp__gitlab__get_merge_request_diffs` (preferred) or open in browser |
| Branch name | `git diff main...{branch} --stat` then `git diff main...{branch}` |
| MR number + repo | `mcp__gitlab__get_merge_request_diffs(project_id="{repo}", mr_iid={number})` |
| Nothing specified | Ask which MR to review |

Also check: MR description, linked tickets, and any test changes.

**For a deep architectural/security review on a large MR**, use `Skill(adlc:code-reviewer)` instead — it dispatches specialist sub-agents for security and performance. This skill handles focused, fast reviews of normal-sized diffs.

## What to Look For

Focus on things that **will cause problems** — not style nits. Only comment on big or breaking issues.

| Category | Examples |
|---|---|
| **Correctness** | Logic errors, off-by-one, race conditions, missing error handling |
| **Data integrity** | Schema mismatches, silent data loss, unvalidated inputs |
| **Operational risk** | Missing retries, no backpressure, unbounded queries, no observability |
| **Security** | Leaked secrets, injection, broken auth, overly broad permissions |
| **Breaking changes** | API contract violations, backwards-incompatible schema changes |
| **Missing tests** | Untested critical paths, tests that don't assert the right thing |

**Ignore:** formatting, naming preferences, import order, minor style choices.

## Output

Summarize findings **in chat only**. Do NOT post comments on the MR.

### Format

```
## MR Review: [title or branch]

**Verdict:** [Approve / Request changes]

### Issues (ranked by severity: critical > major > minor)

1. **[Severity] [Category]:** [One-sentence description]
   - Where: `file:line` (exact path and line number)
   - Code: (quote the problematic snippet)
   - Why it matters: [impact if shipped as-is]
   - Suggestion: [concrete fix]

2. ...

### What's done well (optional, 1 sentence max)
[Only if something is genuinely notable — skip if nothing stands out]

### Overall Assessment
[One paragraph: summarize the MR's quality, risk level, and readiness.]

**Recommendation:** [Approve / Request changes]
```

### Rules

- **1–3 issues max.** Only the ones that absolutely matter. If nothing is
  wrong, say "No issues — looks good to ship."
- Rank every issue by severity:
  - **⛰ Critical** — Blocking, requires immediate action (e.g. fundamentally wrong approach, data loss)
  - **🧱 Major** — Blocking, but other work can continue (e.g. wrong API endpoint, broken logic)
  - **🪨 Minor** — Non-blocking, requires future action (e.g. missing edge case handling)
  - Skip nit-level feedback entirely — it's not worth mentioning.
- Every issue must cite the exact file path and line number. If you can't point to a line, don't raise it.
- Include a concrete suggestion, not just "this is bad."
- Do not pad with minor observations to seem thorough.
