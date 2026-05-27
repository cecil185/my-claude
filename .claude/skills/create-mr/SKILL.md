---
name: create-mr
description: >-
  Creates a GitLab merge request from the current branch. Determines the correct
  repo path, constructs the MR title/description, and runs glab without compound
  cd commands (CLAUDE.md rule). Use when asked to create MR, open a merge request,
  or push and open a review.
when_to_use: >-
  Trigger when user says "create an MR", "open a merge request", "push and open MR",
  "create merge request for DP-XXX", or "open a review". Also trigger after commits
  are complete and user asks to submit work for review.
model: sonnet
effort: low
disable-model-invocation: true
---

# Create MR Workflow

## 1. Determine the repo

Identify which repo the work lives in (ingestion, ingestion-helm, ingestion-terraform, etc.)
based on context. Get the absolute path — e.g. `/Users/cecil/Code/genai/ingestion`.

## 2. Confirm branch and ticket

```bash
git -C /path/to/repo branch --show-current
```

Branch must match the Linear ticket (e.g. `DP-862`). If not, stop and alert the user.

## 3. Push the branch if needed

```bash
git -C /path/to/repo push -u origin HEAD
```

## 4. Create the MR

Use `env -C` to run glab from the repo directory without a compound `cd` command:

```bash
env -C /path/to/repo glab mr create \
  --title "TICKET: concise title" \
  --source-branch BRANCH \
  --target-branch main \
  --description "..."
```

**Target branch:** use `main` unless the repo uses `master` (check with `git -C /path/to/repo remote show origin | grep HEAD`).

## 5. MR description format

```markdown
## Summary

- Bullet points describing what changed and why

## Test plan

- How to verify the change works
```

- Keep the title under 70 characters: `TICKET: what changed`
- Do not add "Closes TICKET" — Linear syncs automatically via the branch name
- Add `--remove-source-branch` to clean up after merge

## CLAUDE.md rules that apply here

- **No compound cd**: always use `env -C /path/to/repo glab ...` — never `cd /path && glab ...`
- **Never push to main/master directly**
- **Confirm before pushing** if the user hasn't explicitly asked to push
