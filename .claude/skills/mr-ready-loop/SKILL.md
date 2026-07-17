---
name: mr-ready-loop
description: >-
  Loops CI/CD pipeline checks and reviewer comments (CodeRabbit and human) on
  a GitLab MR until it's ready for human review — pipeline green and no
  unresolved discussion threads. Delegates all actual fixing to
  /adlc:address-feedback and only orchestrates the poll-fix-repeat cycle.
  Trigger when user says "loop MR feedback", "keep addressing MR feedback
  until ready", "get this MR ready for review", "resolve CI and coderabbit
  loop", "mr ready loop", or "loop until CI passes and comments are resolved".
model: sonnet
---

# MR Ready Loop

Poll a GitLab MR's pipeline status and unresolved discussion threads, and
loop `/adlc:address-feedback <mr>` until both are clean. This skill never
fixes anything itself — it only decides *whether* another pass is needed and
delegates the fix to `adlc:address-feedback`.

**Announce at start:** "I'm using the mr-ready-loop skill to loop CI and review feedback until MR !<mr> is ready."

## Preconditions

- Confirm the current directory is the correct repo (per `CLAUDE.md` worktree
  discipline) — state it explicitly before proceeding.
- `glab` must be authenticated. If not, stop and ask the user to run
  `glab auth login`.
- If no MR number was given, resolve it from the current branch:
  ```bash
  mr_number=$(glab mr view --output json | jq -r '.iid')
  ```

## Loop (max 5 iterations, ask before continuing past that)

For each iteration `i` (1..5):

### 1. Check pipeline status

```bash
pipeline_status=$(glab mr view "$mr_number" --output json | jq -r '.head_pipeline.status // "none"')
echo "Pipeline status: $pipeline_status"
```

- `success` → pipeline is clean.
- `failed` / `canceled` → needs a fix pass.
- `running` / `pending` → poll every 30s, backing off to 60s after 3 checks,
  up to a 10-minute cap per iteration. Do not block with one long sleep —
  loop short waits so you can report progress. This is a Claude Code skill,
  not a Workflow script, so use bash `sleep` in a loop, not `ScheduleWakeup`.
  ```bash
  for wait in 30 30 30 60 60 60 60 60 60 60; do
    status=$(glab mr view "$mr_number" --output json | jq -r '.head_pipeline.status // "none"')
    [[ "$status" == "success" || "$status" == "failed" || "$status" == "canceled" ]] && break
    sleep "$wait"
  done
  ```
- If still running/pending after the cap, report that and stop rather than
  looping indefinitely.

### 2. Check unresolved discussion threads

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

### 3. Decide

- Pipeline `success` **and** `unresolved == 0` → done. Report success and stop.
  Do not merge, approve, or resolve threads yourself — that's for the human
  reviewer.
- Otherwise → run one fix pass:
  ```
  /adlc:address-feedback <mr_number>
  ```
  This command already: switches to the MR's worktree, fetches all paginated
  discussions, categorizes by severity, implements fixes with TDD, requests
  code review, commits, and pushes. Let it fully finish (including its own
  push) before re-checking.
- After the fix pass pushes, **wait 3 minutes** before re-checking anything:
  ```bash
  sleep 180
  ```
  CodeRabbit reviews a push asynchronously and typically takes a couple of
  minutes to post new comments — checking immediately risks reading stale
  discussion state and declaring the MR clean before CodeRabbit has weighed
  in on the latest commits. Then go back to step 1 for the next iteration —
  the push also triggers a new pipeline run, so re-poll that from scratch too.

### 4. Bail-out conditions

Stop and report (don't keep looping) if any of these happen:

- 5 iterations completed and still not clean — report what's still failing
  or unresolved, and ask the user whether to continue.
- `/adlc:address-feedback` makes no commits in a pass (nothing left it could
  fix, e.g. all remaining threads are genuine questions awaiting human
  answers) — report that as the blocker instead of re-running it.
- Pipeline status is `none` (MR has no pipeline configured) — report and
  stop; nothing to poll.

## Final report

One short summary: number of iterations run, final pipeline status, final
unresolved-thread count, and whether the MR is ready for review or blocked
(and on what).
