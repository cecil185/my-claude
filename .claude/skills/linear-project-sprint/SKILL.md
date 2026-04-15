---
name: linear-project-sprint
description: >-
  Loop through all Backlog tickets in a Linear project and attempt to solve
  them in parallel using agent teams. Creates branches off main, runs the ADLC
  execution workflow per ticket, creates GitLab MRs for completed work, and
  leaves descriptive comments on tickets that could not be fully resolved.
  Use when given a Linear project URL and asked to work through its backlog.
model: sonnet
effort: medium
---

# Linear Project Sprint

Execute all **Backlog** tickets in a Linear project in parallel, branching off
`main`, creating GitLab MRs for completed work, and commenting on anything
that could not be resolved.

## Prerequisites

- Linear MCP server authenticated (`mcp__linear-server`)
- GitLab CLI (`glab`) authenticated
- `git gtr` (worktrees plugin) available for isolated branches
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set for parallel execution

---

## Execute a ticket implementation headlessly

For a **single** ticket outside the interactive sprint (scripting, automation, or a one-off run), invoke Claude Code in print mode (`-p`), scope allowed tools, and capture structured output to a file. Substitute the ticket identifier, task wording, result path, and quality commands (`make` vs `just`, etc.) for the target repo.

```bash
claude -p "Execute ticket DP-660: Add structured logging config to all poller DAGs. Read the ticket from Linear, implement the changes, run make lint and make test, then commit with message referencing DP-660." \
  --allowedTools "Edit,Read,Bash,Glob,Grep,Agent" \
  --output-format json > dp660-result.json
```

**Non-interactive task wording** (use inside `-p "..."` or equivalent; replace `DP-XXX` with the real ticket id):

```
Execute ticket DP-XXX. Do not ask me any questions. Read the ticket, read the relevant code, make the changes, run linters and tests, commit, and push. If anything is ambiguous, state your assumption in the commit message and proceed.
```

---

## Step 0 — Parse Arguments

Accept a Linear project URL:

```
/linear-project-sprint https://linear.app/teamworks/project/<slug>/issues
```

Extract the project slug/ID from the URL. If none provided:

```python
AskUserQuestion("Which Linear project URL should I sprint through?")
```

---

## Step 1 — Authenticate & Fetch Backlog Tickets

Extract the project ID from the URL path — it's the hex segment before `/issues`:

```
https://linear.app/teamworks/project/improve-production-resiliency-6b1052fc3cd7/issues
                                                                   ^^^^^^^^^^^^ project ID
```

```python
mcp__linear-server__authenticate()

# Use the extracted project ID, not URL string matching
issues = mcp__linear-server__list_issues(filter={
    "project": {"id": {"eq": "<project-id>"}},
    "state": {"name": {"eq": "Backlog"}}
})
```

If zero tickets found, report and stop.

Present a summary before proceeding:

```
Found N Backlog tickets in <project name>:
  - DP-1: Title
  - DP-2: Title
  ...

Proceeding to execute N tickets across up to 8 parallel agents.
```

---

## Step 2 — Classify & Filter Tickets

For each ticket, determine its readiness and execution type.

### Readiness check

| Condition | Action |
|-----------|--------|
| Blocked by an open ticket | Skip — do not attempt; leave status as Backlog |
| Has a parent issue (is a sub-task) | Skip — will be handled as part of its parent |
| Insufficient detail (no description, no AC, ambiguous scope) | Set status → **Idea**; leave a comment asking what's needed |
| Ready to execute | Proceed to classification |

### Execution classification (for ready tickets)

| Ticket condition | Execution type | ADLC skill |
|-----------------|---------------|------------|
| Has `## Specification` + `## Technical Plan` + sub-issues | Feature (Tier 1) | `adlc:execution` |
| Label = `bug` | Bug fix | `adlc:executing-bug-fixes` |
| Label = `chore` | Chore | `adlc:executing-chores` |
| Everything else | Task | `adlc:executing-tasks` |

**Resolve team ID and workflow state IDs** before spawning agents.

After authenticating, inspect what tools the Linear MCP exposes — look for
tools named `list_workflow_states`, `workflowStates`, `teams`, or similar.
Derive the team from the project itself (don't hardcode a name):

```python
# Get the project to find which team owns it
project = mcp__linear-server__[get_project_tool](id="<project-id>")
TEAM_ID = project.team.id   # use the team that owns this project

# Look up workflow states for that team
states = mcp__linear-server__[workflow_states_tool](teamId=TEAM_ID)
state_map = {s.name: s.id for s in states}

IN_PROGRESS_ID = state_map["In Progress"]
IN_REVIEW_ID   = state_map["In Review"]
PAUSED_ID      = state_map["Paused"]
TRIAGE_ID      = state_map["Triage"]
IDEA_ID        = state_map["Idea"]
```

Inject all five IDs plus TEAM_ID as template variables into every agent prompt.

---

## Step 3 — Execute Tickets in Parallel

Spawn up to 8 Sonnet agents that share a task pool — each agent claims and
executes tickets one at a time until the pool is empty.

```python
# Create a team for this sprint
TeamCreate(name=f"sprint-{project_slug}")

# Add one task per ready ticket — include enough context for agents to act
for ticket in ready_tickets:
    TaskCreate(
        subject=f"{ticket.identifier}: {ticket.title}",
        description="\n".join([
            f"ID: {ticket.identifier}",
            f"URL: {ticket.url}",
            f"Labels: {', '.join(l.name for l in ticket.labels) or 'none'}",
            f"Description:\n{ticket.description or '(none)'}",
        ]),
        activeForm=f"Executing {ticket.identifier}"
    )

# Spawn agents — they each claim tasks from the shared list
max_agents = min(len(ready_tickets), 8)
for i in range(max_agents):
    Agent(
        name=f"sprint-agent-{i+1}",
        model="sonnet",
        mode="bypassPermissions",
        prompt=SPRINT_AGENT_PROMPT,  # full text below
        run_in_background=True,
    )
```

### Sprint Agent Prompt (embed verbatim when spawning)

```
You are a sprint execution agent. Claim tasks from the shared TaskList one at
a time, execute each fully, then move to the next until none remain.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT
  Project:      {project_name}
  Repo:         {working_dir}
  Main branch:  main
  Team ID:      {team_id}
  State IDs:    IN_PROGRESS={in_progress_id}  IN_REVIEW={in_review_id}
                PAUSED={paused_id}  TRIAGE={triage_id}  IDEA={idea_id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## WORKFLOW PER TICKET

### 1. Claim a task
Call TaskList to find an unclaimed task. Claim it immediately:
  TaskUpdate(taskId=<id>, status="in_progress")
If the claim fails, skip and try the next task.

### 2. Load the ticket
Fetch full detail from Linear MCP including description, labels, relations.

### 3. Move ticket → In Progress
  mcp__linear-server__update_issue(id=ticket.id, stateId=IN_PROGRESS_ID)

### 4. Create a worktree branch off main
Slugify the ticket title: lowercase, replace spaces/special chars with `-`,
truncate so the full branch name is ≤ 60 characters.
  Example: "DP-42" + "Add retry logic for S3 uploads" → "dp-42-add-retry-logic-for-s3"

  git gtr new {branch}
  # cd is a SEPARATE Bash call — never chain with &&
  cd ~/worktrees/<repo>/{branch}/

If the branch already exists (resuming a prior sprint):
  git fetch origin {branch}
  git gtr new {branch} --from-remote   # or checkout the existing worktree
  cd ~/worktrees/<repo>/{branch}/
  # Then assess existing progress before continuing

### 5. Execute using the correct ADLC skill
  - Feature (has `## Specification` AND `## Technical Plan` AND sub-issues):
      → `adlc:execution`
      If any of these three are missing, fall through to `adlc:executing-tasks`
      rather than erroring.
  - Bug (label=bug):                    `adlc:executing-bug-fixes`
  - Chore (label=chore):                `adlc:executing-chores`
  - Everything else:                    `adlc:executing-tasks`

### 6. Handle discovered work (during implementation)
  IN-SCOPE  (needed to satisfy this ticket's AC) → fix inline, no new ticket
  OUT-OF-SCOPE (real problem, separate concern)  → create Triage ticket:
    mcp__linear-server__create_issue(
        title="Found: <short description>",
        description="Discovered while working on {ticket.identifier}.\n\n<details>",
        teamId=TEAM_ID,
        stateId=TRIAGE_ID,
        # add a "relates to" relation back to the originating ticket
    )
  Do NOT attempt to fix out-of-scope issues in the current branch.

### 7a. On SUCCESS (all AC met, quality gates green)
Run `just ci` if the repo has a justfile; otherwise `just test && just lint`;
otherwise run the test suite and linter manually. All must pass.
  a. Push and create GitLab MR:
       git push -u origin {branch}
       glab mr create \
         --target-branch main \
         --source-branch {branch} \
         --title "[{ticket.identifier}] {ticket.title}" \
         --description "$(cat <<'EOF'
       ## Summary
       {summary_of_changes}

       ## Ticket
       {ticket.identifier}: {ticket.url}

       ## Changes
       {bulleted_file_list}

       ## Tests
       {test_summary}

       🤖 Generated with Claude Code
       EOF
       )"
  b. Update Linear ticket → In Review:
       mcp__linear-server__update_issue(id=ticket.id, stateId=IN_REVIEW_ID)
       mcp__linear-server__create_comment(issueId=ticket.id, body=f"MR: {mr_url}")
  c. Mark Claude task complete.

### 7b. On PARTIAL / BLOCKED (could not fully resolve)
  a. Commit any progress with a clear message. Push the branch.
  b. Update Linear ticket → Paused:
       mcp__linear-server__update_issue(id=ticket.id, stateId=PAUSED_ID)
  c. Add a comment with structured investigation notes:
       ## Investigation Notes
       **Attempted:** {what_was_tried}
       **Blocked by:** {specific_blocker}
       **Suggested next steps:** {next_steps}
  d. Prepend `## Investigation Notes` to the ticket description if not present.
  e. Mark Claude task complete.

### 8. Signal completion (required before moving on)
  <completion>SPRINT-TASK:{ticket.identifier}:COMPLETE
  Branch: {branch}
  MR: {mr_url or "none — paused"}
  Status: SOLVED | PAUSED
  Summary: {one_line_summary}
  </completion>

### 9. Claim the next task
Loop back to step 1 until TaskList is empty.

## LANDING THE PLANE (after last ticket)

Work is NOT complete until git push has succeeded on every branch with changes.
Never say "ready to push when you are" — push before signalling COMPLETE.

Checklist (run in order):
  1. File Triage tickets for any out-of-scope findings not yet filed.
  2. Run `just ci` on any branches with uncommitted or unpushed changes.
  3. Verify every ticket is in In Review or Paused — none left In Progress.
  4. Push all branches:
       git pull --rebase && git push
       git status   # must show "up to date with origin"
  5. Clean up stashes.

## HARD RULES
  ✅  Claim (→ In Progress) before starting any work
  ✅  Use Linear MCP for all status updates — no markdown TODO lists
  ✅  One branch per ticket
  ✅  Out-of-scope findings → Triage ticket with "relates to" link
  ✅  Run `just ci` before declaring success
  ❌  Never commit directly to main
  ❌  Never work on a ticket whose claim failed
  ❌  Never leave a ticket In Progress when moving on
  ❌  Never say "ready to push" — always push yourself
```

---

## Step 4 — Collect Results

Aggregate completion signals and present the sprint summary:

```markdown
## Sprint Results — <project name>

### Solved (MR created) — In Review
- [DP-1](url): Title — MR !123
- [DP-3](url): Title — MR !125

### Paused (needs input)
- [DP-2](url): Title — investigation notes added to ticket
- [DP-4](url): Title — blocked on missing credentials

### Needs Clarification — moved to Idea
- [DP-5](url): Title — no acceptance criteria; comment left asking for AC

### Skipped (blocked or sub-task)
- [DP-6](url): Title — blocked by DP-1 (still open)

Total: N solved, M paused, K needs-clarification, J skipped
```

---

## Step 5 — Final State Verification

Check every ticket from the original Backlog list landed in the right state.
Correct anything still showing **In Progress**.

| Outcome | Expected state |
|---------|---------------|
| MR created | **In Review** |
| Attempted but blocked | **Paused** |
| Needs more definition | **Idea** |
| Blocked / sub-task (not attempted) | **Backlog** |

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Linear MCP unavailable | Abort; instruct user to configure MCP and restart |
| `glab` not authenticated | Run `glab auth login` and retry |
| No Backlog tickets | Report and stop |
| Agent fails mid-ticket | Log failure, leave Linear comment → Paused, continue |
| `just ci` unavailable | Run `just test && just lint` manually |
| `just ci` failures | Fix or document as blocker in ticket comment → Paused |
| No acceptance criteria | Move ticket → Idea; leave comment asking for AC |

---

## Resuming a Partial Sprint

Re-run with the same project URL. The skill re-fetches and attempts:
- **Backlog** tickets (not yet started)
- **Paused** tickets (previously attempted but blocked — retried by default;
  pass `--skip-paused` to exclude them)

Tickets in **In Review**, **Done**, or **Idea** are automatically skipped.

---

## Notes

- **Parallel cap:** 8 concurrent agents — adjust by passing `--max-agents N`
- **Branch naming:** `{ticket-id-lowercase}-{slug}` e.g. `dp-42-add-retry-logic`
- **MR target:** always `main` — Backlog items are independent, not stacked
- **glab flag:** `--description` (not `--body`) when creating MRs
- **No compound `cd`:** always separate Bash calls for `cd` and subsequent commands
