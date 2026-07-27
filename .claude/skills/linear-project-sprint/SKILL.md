---
name: linear-project-sprint
description: >-
  Loops through all Backlog tickets in a Linear project and attempts to solve them in parallel
  using agent teams. Creates branches off main, runs the ADLC execution workflow per ticket,
  creates GitLab MRs for completed work, and leaves investigation notes on tickets that could
  not be fully resolved. Trigger when user provides a Linear project URL and asks to "sprint
  through the backlog", "work through this project", "execute all tickets", or "run the sprint".
model: sonnet
effort: medium
disable-model-invocation: true
---

# Linear Project Sprint

Execute all **Backlog** tickets in a Linear project in parallel, branching off
`main`, creating GitLab MRs for completed work, and commenting on anything
that could not be resolved.

**Example:** `/linear-project-sprint https://linear.app/teamworks/project/improve-production-resiliency-6b1052fc3cd7/issues`
→ fetches Backlog tickets, classifies each, spawns up to 8 agents, creates MRs for completed work, moves blocked tickets to Paused with investigation notes.

Supporting files:
- [agent-prompt.md](agent-prompt.md) — the sprint agent prompt, embedded verbatim when spawning
- [reference.md](reference.md) — ID resolution, spawn code, report template, error handling, headless single-ticket mode

## Prerequisites

- Linear MCP server authenticated (`mcp__linear-server`)
- GitLab CLI (`glab`) authenticated
- `git gtr` (worktrees plugin) available for isolated branches
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set for parallel execution

---

## Step 0 — Parse Arguments

Accept a Linear project URL:

```
/linear-project-sprint https://linear.app/teamworks/project/<slug>/issues
```

Extract the project ID from the URL path — it's the hex segment before `/issues`:

```
https://linear.app/teamworks/project/improve-production-resiliency-6b1052fc3cd7/issues
                                                                   ^^^^^^^^^^^^ project ID
```

If no URL provided:

```python
AskUserQuestion("Which Linear project URL should I sprint through?")
```

---

## Step 1 — Authenticate & Fetch Backlog Tickets

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

**Resolve team ID and workflow state IDs** before spawning agents — derive the team
from the project itself rather than hardcoding a name. See
[resolving team and workflow state IDs](reference.md#resolving-team-and-workflow-state-ids).

---

## Step 3 — Execute Tickets in Parallel

Spawn up to 8 Sonnet agents that share a task pool — each agent claims and
executes tickets one at a time until the pool is empty. Use the
[spawn code](reference.md#spawn-code): create the sprint team, add one task per ready
ticket with enough context to act on, then spawn `min(len(ready_tickets), 8)` background
agents.

Each agent's prompt is the full text of [agent-prompt.md](agent-prompt.md), embedded
verbatim with TEAM_ID and the five state IDs substituted in.

---

## Step 4 — Collect Results

Aggregate the agents' completion signals and present the sprint summary using the
[sprint results template](reference.md#sprint-results-template) — solved, paused,
needs-clarification, and skipped sections with totals.

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

For failure situations during the run (MCP down, `glab` unauthenticated, agent crash,
`just ci` failures), follow [error handling](reference.md#error-handling).

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
- **Single ticket, non-interactive?** Use [headless single-ticket execution](reference.md#headless-single-ticket-execution) instead of the full sprint.
