---
name: mr-ready-loop
description: >-
  Loops CI/CD pipeline checks and reviewer comments (CodeRabbit and human) on
  a GitLab MR or GitHub PR until it's ready for human review — pipeline/checks
  green and no unresolved discussion threads. Replies to every thread it
  addresses or ignores and resolves it automatically; threads awaiting human
  input get a reply but are left unresolved. Delegates fixing to
  /adlc:address-feedback on GitLab, or an inline gh-based fix pass on GitHub,
  and only orchestrates the poll-fix-repeat cycle.
  Trigger when user says "loop MR feedback", "loop PR feedback", "keep
  addressing MR feedback until ready", "get this MR/PR ready for review",
  "resolve CI and coderabbit loop", "mr ready loop", "pr ready loop", or "loop
  until CI passes and comments are resolved".
model: sonnet
disable-model-invocation: true
---

# MR/PR Ready Loop

Poll a GitLab MR's or GitHub PR's pipeline/check status and unresolved
discussion threads, and loop a fix pass until both are clean. This skill
never fixes anything itself — it only decides *whether* another pass is
needed and delegates the fix.

**Announce at start:** "I'm using the mr-ready-loop skill to loop CI and review feedback until <MR !N / PR #N> is ready."

## Preconditions

- Confirm the current directory is the correct repo (per `CLAUDE.md` worktree
  discipline) — state it explicitly before proceeding.
- **Detect the host** from the git remote and set `$platform` for the rest of
  the loop:
  ```bash
  remote_url=$(git remote get-url origin)
  if [[ "$remote_url" == *"gitlab"* ]]; then
    platform=gitlab
  elif [[ "$remote_url" == *"github"* ]]; then
    platform=github
  else
    echo "Unrecognized remote host: $remote_url"
    exit 1
  fi
  echo "Detected platform: $platform"
  ```
  If a URL was given as input, cross-check it matches the detected platform
  (a `github.com/.../pull/N` URL against a GitLab remote, or vice versa, is a
  mismatch — stop and ask the user which repo/host they meant).
- The right CLI must be authenticated:
  - GitLab: `glab auth status`. If not authenticated, stop and ask the user
    to run `glab auth login`.
  - GitHub: `gh auth status`. If not authenticated, stop and ask the user to
    run `gh auth login`.
- If no MR/PR number was given, resolve it from the current branch:
  ```bash
  # GitLab
  mr_number=$(glab mr view --output json | jq -r '.iid')
  # GitHub
  pr_number=$(gh pr view --json number -q '.number')
  ```

## Loop (max 5 iterations, ask before continuing past that)

For each iteration `i` (1..5):

### 1. Check pipeline/check status

GitLab:
```bash
pipeline_status=$(glab mr view "$mr_number" --output json | jq -r '.head_pipeline.status // "none"')
echo "Pipeline status: $pipeline_status"
```
- `success` → clean. `failed` / `canceled` → needs a fix pass.
- `running` / `pending` → poll (see below).
- `none` → no pipeline configured; report and stop (bail-out condition).

GitHub:
```bash
check_status=$(gh pr view "$pr_number" --json statusCheckRollup \
  -q '(.statusCheckRollup | map(.conclusion // .status) | if length == 0 then "none"
      elif any(. == "FAILURE" or . == "failed") then "failed"
      elif any(. == "PENDING" or . == "IN_PROGRESS" or . == "pending" or . == "queued") then "pending"
      else "success" end)')
echo "Check status: $check_status"
```
- `success` → clean. `failed` → needs a fix pass.
- `pending` → poll (see below).
- `none` → no checks configured; report and stop (bail-out condition).

Polling (either platform, when status is running/pending): poll every 30s,
backing off to 60s after 3 checks, up to a 10-minute cap per iteration. Do
not block with one long sleep — loop short waits so you can report progress.
This is a Claude Code skill, not a Workflow script, so use bash `sleep` in a
loop, not `ScheduleWakeup`.
```bash
for wait in 30 30 30 60 60 60 60 60 60 60; do
  # re-run the platform-appropriate status check above
  [[ "$status" == "success" || "$status" == "failed" || "$status" == "canceled" ]] && break
  sleep "$wait"
done
```
If still running/pending after the cap, report that and stop rather than
looping indefinitely.

### 2. Check unresolved discussion threads

GitLab:
```bash
project_id=$(glab mr view "$mr_number" --output json | jq -r '.project_id')
unresolved=$(glab api --paginate "projects/${project_id}/merge_requests/${mr_number}/discussions?per_page=100" \
  | jq -s 'add | map(select(
      (.notes | any(.system == false))
      and (.notes | map(select(.resolvable == true)) | length > 0)
      and (.notes | map(select(.resolvable == true)) | all(.resolved == false))
    )) | length')
echo "Unresolved non-system threads: $unresolved"
```
`--paginate` is required — never drop it, or threads past page 1 are missed
(same rule `addressing-mr-feedback` relies on).

GitHub (review threads are only exposed via GraphQL, not REST):
```bash
owner_repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
owner="${owner_repo%/*}"; repo="${owner_repo#*/}"
unresolved=$(gh api graphql --paginate -f query='
  query($owner:String!,$repo:String!,$pr:Int!,$endCursor:String){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100, after:$endCursor){
          nodes { isResolved isOutdated comments(first:1){nodes{author{login}}} }
          pageInfo{hasNextPage endCursor}
        }
      }
    }
  }' -F owner="$owner" -F repo="$repo" -F pr="$pr_number" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes' \
  | jq -s 'add | map(select(.isResolved == false)) | length')
echo "Unresolved review threads: $unresolved"
```
Use `--paginate` on the GraphQL call too — a PR with more than 100 review
threads would otherwise silently drop the rest.

### 3. Classify each unresolved thread

Before deciding what to do, build a per-thread status table — this is what
gets reported to the user, and it's how you catch "already fixed in code but
nobody clicked resolve" without silently resolving it yourself.

For each unresolved thread (GitLab: unresolved discussion; GitHub: review
thread with `isResolved == false`), pull its full comment body/reviewer, the
file/line it's pinned to, and whether the platform marked it stale relative
to the current diff (GitLab: compare the discussion's `position` commit SHA
against HEAD; GitHub: the `isOutdated` field from the same GraphQL query).
Then classify:

- **Addressed** — the code at/near the pinned location now does what the
  comment asked (verify by reading the current code, not just by trusting
  `isOutdated`/stale-position flags — those mean "the diff moved," not
  "the concern was fixed"). Mark **resolvable: yes**.
- **Ignored / not yet addressed** — the concern is still valid against
  current code. Mark **resolvable: no** — this is what the next fix pass
  should target.
- **Awaiting human input** — a genuine question, or a suggestion the fix
  pass deliberately left for a human judgment call. Mark **resolvable:
  no** (a human needs to answer or decide first, not just click resolve).

Present the table like:

```
| # | Reviewer | File:Line | Summary | Status | Resolvable? |
|---|----------|-----------|---------|--------|-------------|
| 1 | codex    | stream.rs:91 | duplicate index | Addressed (commit 3bb9686) | Yes |
| 2 | codex    | tool.rs:52   | duplicate ID    | Addressed (commit 3bb9686) | Yes |
| 3 | codex    | stream.rs:117| delta after stop| Addressed (commit 1a59a4e) | Yes |
```

For every thread classified **Addressed** or **Ignored / not yet addressed**,
reply then resolve it in the same pass — do this once per thread per loop
iteration (don't re-reply/re-resolve a thread you already handled in an
earlier iteration unless its classification changed). Reply with exactly two
sentences: first, "Implemented" or "Ignored"; second, a one-sentence
justification — only include the second sentence if it adds information the
first doesn't already convey (e.g. "Implemented." alone is fine if the fix
is self-evident from the diff; "Ignored — this is a style preference, not a
correctness issue." if it needs explaining).

Threads classified **Awaiting human input** get the reply ("Awaiting human
input" plus the one-sentence justification if needed) but are **never
resolved** — a human still needs to answer or decide. Leave those unresolved
and call them out explicitly in the final report.

```bash
# GitLab — reply to a discussion thread, then resolve it
glab api "projects/${project_id}/merge_requests/${mr_number}/discussions/${discussion_id}/notes" \
  -X POST -f body="Implemented — rejects deltas/stops for an index that already terminated."
glab api "projects/${project_id}/merge_requests/${mr_number}/discussions/${discussion_id}" \
  -X PUT -f resolved=true

# GitHub — reply to a review thread, then resolve it
gh api graphql -f query='
  mutation($threadId:ID!,$body:String!){
    addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$threadId, body:$body}){ comment{id} }
  }' -F threadId="$thread_id" -F body="Implemented — rejects deltas/stops for an index that already terminated."
gh api graphql -f query='
  mutation($threadId:ID!){
    resolveReviewThread(input:{threadId:$threadId}){ thread{id} }
  }' -F threadId="$thread_id"
```

### 4. Decide

- Status `success`/clean **and** every remaining unresolved thread is
  classified **Awaiting human input** (all **Addressed**/**Ignored** threads
  were replied to and resolved in step 3) → done. Report success and stop.
  Do not merge or approve the MR/PR yourself, and do not resolve **Awaiting
  human input** threads — those are for the human reviewer.
- Otherwise → run one fix pass:
  - **GitLab:**
    ```
    /adlc:address-feedback <mr_number>
    ```
    This command already: switches to the MR's worktree, fetches all
    paginated discussions, categorizes by severity, implements fixes with
    TDD, requests code review, commits, and pushes.
  - **GitHub:** `/adlc:address-feedback` is GitLab-only (it calls `glab`
    directly), so run the equivalent inline, mirroring the same steps:
    1. Ensure you're on the PR's branch (`gh pr checkout <pr_number>`), or
       find/create its worktree per the same worktree-discipline rules
       `addressing-mr-feedback` uses.
    2. Fetch all PR review comments: `gh pr view <pr_number> --json
       comments,reviews`, plus the unresolved review threads fetched in step
       2 above (for file/line context, pull each thread's comments via the
       same GraphQL query, expanding `comments(first:100)`).
    3. Categorize into critical / important / minor / questions /
       suggestions — same scheme as `addressing-mr-feedback` — and present
       the breakdown to the user.
    4. For questions: investigate, draft a response, and get user approval
       before posting (`gh pr comment`).
    5. Implement all actionable items directly on the branch, priority order
       critical → important → minor → suggestions. TDD for bugs/behavioral
       changes (failing test first); direct fix for style/naming/docs. One
       commit per feedback item.
    6. Run `Skill(adlc:requesting-code-review)` on the batch of changes
       before pushing; apply any Critical/Major feedback from that review.
    7. `git push`.
  Let the fix pass fully finish (including its own push) before re-checking.
- After the fix pass pushes, **wait 3 minutes** before re-checking anything:
  ```bash
  sleep 180
  ```
  CodeRabbit reviews a push asynchronously and typically takes a couple of
  minutes to post new comments — checking immediately risks reading stale
  discussion state and declaring the MR/PR clean before CodeRabbit has
  weighed in on the latest commits. Then go back to step 1 for the next
  iteration — the push also triggers a new pipeline/check run, so re-poll
  that from scratch too.

### 5. Bail-out conditions

Stop and report (don't keep looping) if any of these happen:

- 5 iterations completed and still not clean — report what's still failing
  or unresolved, and ask the user whether to continue.
- The fix pass (GitLab or GitHub) makes no commits in a pass (nothing left
  it could fix — e.g. every remaining unresolved thread is classified
  **Awaiting human input** in step 3) — report that as the blocker instead
  of re-running it.
- Pipeline/check status is `none` (MR/PR has no pipeline/checks configured)
  — report and stop; nothing to poll.

## Final report

Short summary: number of iterations run, final pipeline/check status, and
whether the MR/PR is ready for review or blocked (and on what) — plus the
per-thread table from step 3 covering every thread touched across all
iterations, so the user can see at a glance what was replied to and
resolved automatically versus what's still unresolved and awaiting a human
answer.
