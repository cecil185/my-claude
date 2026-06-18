---
name: risk-assessment
description: >-
  Narrow, failure-mode-focused review of a GitLab MR. Returns ≤5 sharp findings ranked by
  impact × evidence. Stays on production failure modes only — no style or naming feedback.
  Skips tests, markdown, and lockfiles on the first pass; consults tests only after finding
  a plausible bug to judge coverage. Trigger when user says "what could go wrong", "failure
  modes", "risk review", "review this MR for risks", "what are the risks here", or
  "production risks".
model: claude-opus-4-6
effort: high
---

# What Could Go Wrong?

Produce a short, sharp report of the most plausible **production failure modes** introduced by a GitLab MR. Fewer, sharper findings. Do not pad.

## Inputs

Accept exactly one of:
1. GitLab MR URL
2. MR IID + project path
3. "current branch" — resolved via `glab mr view --output json`

**Flag:** `--json` — emit structured JSON instead of markdown.

If no identifier is provided and no open MR exists on the current branch, ask once. Do not guess.

## Collecting MR Context

Fetch all data via `glab` (not web scraping).

**Required:**
- Full diff: `glab mr diff <iid>`
- Title, description, changed files: `glab mr view <iid> --output json`
- Test files in diff (paths matching `test_*`, `*_test.*`, `tests/`, `*.spec.*`)

**Best-effort:** CI status, CODEOWNERS, linked ticket from branch name or description.

**Error handling:**
- Auth failure → hard-fail: `glab is not authenticated. Run \`glab auth login\` and retry.`
- Empty diff → print `MR has no changes` and exit.

**Skip and note in summary:** lockfiles, generated files (`*.pb.go`, `*_pb2.py`, `*.gen.*`, `dist/`, `__snapshots__/`).

**Early exits:**
- Doc-only, formatting-only, or pure dep bump → emit `No significant risks introduced.` and exit.
- Large diffs (>~2000 lines) → analyze the 1–2 riskiest hunks per file; note partial coverage in the summary.

## Analysis

For each non-excluded hunk, ask:
1. What new behavior or invariant does this introduce? (data integrity, idempotency, auth, ordering)
2. Under what concurrent, partial-failure, or retry condition would it misbehave?
3. What would the production symptom look like?
4. Is there a test that would catch it?

### Impact

| Level | Definition |
|---|---|
| **critical** | Will cause an incident on rollout |
| **high** | Likely incident under a realistic edge case |
| **medium** | User-visible bug or operational toil |
| **low** | Skip — do not report |

### Evidence

| Level | Definition |
|---|---|
| **high** | Direct evidence in the diff; mechanistic failure path |
| **medium** | Reasonable inference from diff + context |
| **low** | Speculative; include only if impact is high or critical |

Rank findings by impact, then evidence. Cap at 5. Emit fewer if warranted. An empty findings list is valid.

## Output

### Markdown (default)

```markdown
### Highest-risk areas to review

1. **<title>**
   - File: `<path>`
   - Impact: <level>  •  Evidence: <level>
   - Why: <causal path to production failure> (400 character maximum)
```

## Rules

1. Every finding must cite a file.
2. No fabrication. "No significant risks" beats a filler finding.
