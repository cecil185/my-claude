---
name: worktree-open
description: >
  Creates a git worktree in ./worktrees/<branch> for the current repo, then opens it in a new
  Cursor window. Trigger when user says "open worktree", "create a worktree", "create worktree
  for DP-XXX", "open DP-XXX in Cursor", "worktree open <branch>", "open this branch in Cursor",
  or "open this in a new window".
allowed-tools: Bash(git worktree *), Bash(git -C * worktree *), Bash(git branch *), Bash(git rev-parse *), Bash(ls *), Bash(cursor *)
model: sonnet
effort: low
disable-model-invocation: true
---

Create a worktree in `./worktrees/<branch>` relative to the current repo root, then open it in Cursor.

## Step 1: Resolve the repo root and branch name

Get the repo root:

```
git rev-parse --show-toplevel
```

Determine the branch name from the user's input (e.g. `DP-123`). If no branch was given, use the current branch:

```
git branch --show-current
```

## Step 2: Check if the worktree already exists

```
git worktree list --porcelain
```

If a worktree at `<repo-root>/worktrees/<branch>` is already listed, skip creation and go straight to Step 4.

## Step 3: Create the worktree

Check whether the branch exists with `git branch --list <branch>` (empty output = it doesn't), then create the worktree at `<repo-root>/worktrees/<branch>`.

Branch exists locally:

```
git worktree add <repo-root>/worktrees/<branch> <branch>
```

New branch:

```
git worktree add -b <branch> <repo-root>/worktrees/<branch>
```

## Step 4: Open in Cursor

```
cursor <repo-root>/worktrees/<branch>
```

## Step 5: Report

Print one line confirming the worktree path and that Cursor was launched, e.g.:

```
Worktree ready: /Users/cecil/Code/genai/ingestion/worktrees/DP-123
Opened in Cursor.
```

## Notes

- Never create worktrees outside `./worktrees/` relative to the repo root.
- If `cursor` is not found in PATH, print the worktree path and tell the user to open it manually.
- Do not switch the current shell's working directory.
