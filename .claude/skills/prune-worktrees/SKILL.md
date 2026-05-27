---
name: prune-worktrees
description: >
  Finds and lists all git worktrees across every repo in the genai workspace, then prints
  ready-to-run removal commands for each. Use when the user says "list my worktrees",
  "show worktrees", "clean up branches", or "what worktrees do I have".
when_to_use: >
  Trigger when user says "list worktrees", "show my worktrees", "what branches are checked out",
  "clean up my worktrees", or "prune worktrees".
allowed-tools: Bash(git worktree list *), Bash(git worktree prune *), Bash(git -C * worktree list *), Bash(ls *)
model: sonnet
effort: low
---

Scan every git repo in the genai workspace for linked worktrees, then print ready-to-run removal commands.

## Step 1: Discover repos

List the top-level directories under the workspace root:

```
ls /Users/cecil/Code/genai/
```

Filter to directories that are git repos by checking for a `.git` file or directory in each.

## Step 2: List worktrees in every repo

For each repo directory, run:

```
git -C <repo-path> worktree list --porcelain
```

Parse the output. Each worktree block has three lines:
- `worktree <path>`
- `HEAD <sha>`
- `branch refs/heads/<branch>` (or `detached`)

The **main worktree** is the first entry in the list — its path equals the repo directory itself. Skip it.

Any subsequent entries are **linked worktrees** — these are candidates for removal.

## Step 3: Print results

Output a table grouped by repo:

```
## ingestion-terraform

  Linked worktrees:
  - /Users/cecil/Code/genai/ingestion-terraform-DP-1261  (branch: DP-1261)

## ingestion
  No linked worktrees.
```

If no repo has any linked worktrees, say so and stop.

## Step 4: Print removal commands

For every linked worktree found, print the exact commands the user should run — one block per repo that has worktrees. Always include both the `git worktree remove` command and a `rm -rf` command for the directory:

```
# ingestion-terraform
rm -rf /Users/cecil/Code/genai/ingestion-terraform-DP-1261 &&
git -C /Users/cecil/Code/genai/ingestion-terraform worktree prune
```

```
# ingestion-dags (stale ref only)
git -C /Users/cecil/Code/genai/ingestion-dags worktree prune
```

Do NOT run any of the removal commands — only print them. The user decides what to execute.

## Notes

- Never remove the main worktree (the first entry in `git worktree list`).
- `git worktree prune` cleans up stale metadata even when there's nothing to remove — always include it.
- If a linked worktree path no longer exists on disk, still include `git worktree prune` so the stale ref is cleaned up.
