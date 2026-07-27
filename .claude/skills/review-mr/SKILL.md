---
name: review-mr
description: >-
  Reviews a GitLab merge request and returns only approve or request-changes
  with line-level comments. Trigger when user says "review this MR", "review
  the merge request", "critique this diff", "look at MR !123", "look at merge
  request !123" or provides a GitLab MR URL.
model: claude-opus-4-6
effort: high
---

# Review Merge Request

Review a merge request, then classify as either **approve** (no comments) or
**request changes** (with specific comments and lines to post those comments).
No noise. Max output: **100 words**.

Do not modify code. Do not post comments to the MR.

## Process

1. Get the ticket number from the MR name/description; read the Linear ticket for the goal.
2. Fetch the MR via **GitLab MCP only** (`get_merge_request`, `get_merge_request_diffs`). Never web-fetch or scrape. If MCP is unauthenticated, stop and ask the user to authenticate via `/mcp`.
3. List every changed file, then read each changed file **in full** (not only diff hunks).
4. Verify every claim against source. If you cannot verify, drop it — do not raise unverified issues.
5. Focus on problems that will break things: correctness, data integrity, ops risk, security, breaking changes, missing critical tests. Ignore style/nits.

| Input | How to get the diff |
|---|---|
| MR URL | Parse project path + MR IID → `get_merge_request_diffs` |
| Branch name | `get_merge_request` then `get_merge_request_diffs` |
| MR number + repo | `get_merge_request_diffs(project_id, mr_iid)` |
| Nothing specified | Ask which MR |

For a deep architectural/security review on a large MR, use `Agent(subagent_type: "adlc:code-reviewer")` instead.

## Output (≤100 words)

Exactly one of these forms. Nothing else.

### Approve

```
**Verdict:** approve
```

### Request changes

```
**Verdict:** request-changes

1. `path/to/file:LINE` — [issue]. Fix: [concrete suggestion]
2. ...
```

### Rules

- Verdict is only `approve` or `request-changes` (no `comment`).
- Approve ⇒ zero comments. Request-changes ⇒ 1–3 comments max, each with exact `file:line` and a concrete fix.
- Every comment must cite a line you verified in source. If you can't point to a line, don't raise it.
- Do not invent concerns. Do not pad. Do not summarize "what's done well."
