---
name: review-mr
description: >-
  Reviews a GitLab merge request and surfaces the most important issues with verified evidence.
  Use when asked to "review this MR", "critique this diff", "look at merge request !123",
  or "what do you think of this PR".
when_to_use: >-
  Trigger when user says "review this MR", "review the merge request", "critique this diff",
  "look at MR !123", "check this PR", or provides a GitLab MR URL.
model: claude-opus-4-6
effort: high
---

# Review Merge Request

Produce a focused, high-signal critique of a merge request. No noise.
Do not flag anything you haven't verified by reading the actual code.
Before claiming something is missing or wrong, **search the source files** to
confirm — do not assume. If you cannot verify a concern, label it `[UNVERIFIED]`
and state what you'd need to check.

## Before reading any code

Get the ticket number from the MR name or description and then read the Linear ticket to understand the goal of the MR.

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

**Fetch via GitLab MCP only.** Never use a web URL fetch, browser navigation,
or copy-pasted diff. If the GitLab MCP server is not authenticated, stop and
ask the user to authenticate via `/mcp` before continuing — do not fall back
to web scraping.

| Input | How to get the diff |
|---|---|
| MR URL | Parse project path + MR IID from URL, then `mcp__GitLab__get_merge_request_diffs` |
| Branch name | `mcp__GitLab__get_merge_request` to find the MR for the branch, then `mcp__GitLab__get_merge_request_diffs` |
| MR number + repo | `mcp__GitLab__get_merge_request_diffs(project_id="{repo}", mr_iid={number})` |
| Nothing specified | Ask which MR to review |

Also fetch via MCP: MR description, linked tickets, existing review comments,
and any test changes.

## Editing policy

**Do NOT make any code edits, file writes, commits, or MR comments as part
of a review.** This skill is read-only. Output the review in chat only. If
the user wants the issues fixed, they will ask in a follow-up message — only
then make changes.

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

Summarize findings **in chat only**. Do NOT post comments on the MR or edit
any files (see Editing policy above).

### Format

```
## MR Review: [title or branch]

### Verification Table

Map every claim in this review to the source evidence that supports it.
A row exists for each issue raised below. No issue may appear in the
ranked list without a corresponding verified row.

| Claim | File:Line | Evidence (quoted snippet) | Verified? |
|---|---|---|---|
| [one-line claim] | `path/to/file.py:42` | `quoted code` | ✓ / [UNVERIFIED] |

### Issues (ranked: critical → major → minor)

1. **[Critical | Major | Minor] [Category]:** [One-sentence description]
   - Where: `file:line`
   - Code: (quote the problematic snippet)
   - Why it matters: [impact if shipped as-is]
   - Suggestion: [concrete fix]

2. ...

### What's done well (optional, 1 sentence max)
[Only if something is genuinely notable — skip if nothing stands out]

**Verdict:** approve | request-changes | comment
```

### Rules

- The review **must end with a single-line verdict**: exactly one of
  `approve`, `request-changes`, or `comment`. Nothing after it.
- Rank every issue by severity (`critical`, `major`, `minor`). Drop nits.
  - **Critical** — Blocking, requires immediate action (e.g. data loss, wrong approach)
  - **Major** — Blocking, but other work can continue (e.g. wrong API, broken logic)
  - **Minor** — Worth raising but not blocking (include sparingly)
- Every issue must appear in the **Verification Table** with a quoted
  source snippet. If you cannot quote the source, mark the row
  `[UNVERIFIED]` and do not raise it as a ranked issue.
- **1–3 issues max.** If nothing is wrong, say "No issues — looks good to ship."
- Every issue must cite the exact file path and line number. If you can't
  point to a line, don't raise it.
- Include a concrete suggestion, not just "this is bad."
- Do not pad with minor observations to seem thorough.
- **Do not make any code edits.** Review only. Wait for an explicit
  follow-up if the user wants fixes applied.
