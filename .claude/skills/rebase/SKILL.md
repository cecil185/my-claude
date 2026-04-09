---
description: Rebase current branch onto its base branch
allowed-tools: Bash(git:*), Read, Edit, Grep, Glob
model: sonnet
effort: low
---

Rebase the current branch onto the latest version of its upstream base branch. Follow these steps carefully:

## Step 1: Determine context

Run these in parallel:
- `git branch --show-current` to get the current branch name
- `git status --short` to check for uncommitted changes
- `git log --oneline -5` to see recent commits

## Step 2: Check for uncommitted changes

If there are uncommitted changes (staged or unstaged):
- STOP and inform the user they have uncommitted changes
- Ask whether they want to stash changes first, commit them, or abort
- Do NOT proceed with the rebase until changes are handled

## Step 3: Determine the base branch

The base branch is typically `main` or `master`. Check which exists:
- `git branch --list main master`

If the user provided an argument ($1), use that as the base branch instead.

## Step 4: Fetch and rebase

1. Fetch the latest from the remote: `git fetch origin`
2. Rebase onto the base branch: `git rebase origin/<base-branch>`

## Step 5: Handle conflicts

If the rebase encounters conflicts:

1. Run `git diff --name-only --diff-filter=U` to list all conflicted files
2. For each conflicted file:
   a. Read the file to understand the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   b. Analyze both sides of each conflict — understand the intent of the current branch changes vs the base branch changes
   c. Attempt to resolve the conflict by editing the file to merge both changes correctly
   d. After resolving, run `git add <file>` to mark it resolved
3. After resolving all files, run `git rebase --continue`
4. If new conflicts arise in subsequent commits, repeat the process

**If `package-lock.json` (or `yarn.lock`, `pnpm-lock.yaml`) has conflicts:**
- Do NOT attempt to manually resolve the lock file — it will almost certainly produce an invalid result
- Accept the base branch version: `git checkout --theirs package-lock.json && git add package-lock.json`
- After the rebase completes successfully, regenerate the lock file by running the appropriate install command (`npm install`, `yarn install`, or `pnpm install`)
- Commit the regenerated lock file: `git add package-lock.json && git commit -m "chore: regenerate lock file after rebase"`

**If you cannot confidently resolve a conflict** (e.g., both sides made incompatible changes to the same logic, or business logic decisions are needed):
- Show the user the conflicting sections
- Explain what each side was trying to do
- Ask the user which approach to take or how to merge them
- Do NOT guess on ambiguous business logic

## Step 6: Report result

After successful rebase:
- Show `git log --oneline -10` so the user can verify the history looks correct
- Report how many commits were replayed
- If the branch has a remote tracking branch, print a brief summary that includes:
  - Number of commits replayed and base branch
  - Any files that had conflicts and how each was resolved (one line per file)
  - Then run `git push --force-with-lease` — the permission prompt will handle user approval, do NOT ask separately