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

## Gather the Diff

Use one of these approaches depending on what the user provides:

| Input | How to get the diff |
|---|---|
| MR URL | Open in browser, read the changes tab |
| Branch name | `git diff main...{branch} --stat` then `git diff main...{branch}` |
| MR number + repo | Use GitLab MCP `get_merge_request_diffs` if available |
| Nothing specified | Ask which MR to review |

Also check: MR description, linked tickets, and any test changes.

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
