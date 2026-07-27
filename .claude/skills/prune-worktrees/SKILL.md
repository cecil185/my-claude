---
name: prune-worktrees
description: >
  Finds and lists all git worktrees across every repo in the genai workspace, then prints
  ready-to-run removal commands for each. Trigger when user says "list my worktrees",
  "show worktrees", "clean up branches", "what worktrees do I have", "list worktrees",
  "show my worktrees", "what branches are checked out", or "prune worktrees".
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

Skip the first entry — that is the main worktree (its path equals the repo directory). Every subsequent entry is a linked worktree and a removal candidate.

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

Always include `git worktree prune` in each block, even when the worktree path no longer exists on disk, so stale refs get cleaned up.
