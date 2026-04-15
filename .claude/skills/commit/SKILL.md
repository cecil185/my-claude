---
name: commit
description: >-
  Use when the user asks to commit, stage, or save changes — runs lint, tests,
  then stages, commits, pushes, and opens a merge request in one chained command.
model: sonnet
effort: low
---

# Commit Workflow

## 1. Determine the ticket and validate the branch

- Get your current in-progress Linear ticket using `mcp__linear-server__get_my_issues` (filter to "In Progress").
- Extract the current git branch name using `git branch --show-current`.
- Verify the branch name matches the ticket number (e.g. ticket `DP-600` → branch must be `DP-600`). If they don't match, stop and alert the user.

## 2. Run lint

Run `just lint` from the repo root. If lint fails, fix the issues and re-run until clean.

**If `just lint` is unavailable:**, skip this step.

## 3. Run tests

Run `just test` from the repo root. If tests fail, stop and report the failures — do not proceed.

**If `just test` is unavailable:**, skip this step.

## 4. Stage, commit, push, and open MR

Substitute `{TICKET}` and `{Title}` with the actual ticket identifier and a concise title:

```bash
git add -p && \
git commit -m "$(cat <<'EOF'
{TICKET}: {Title}
EOF
)" && \
git push -u origin HEAD && \
glab mr create --fill --target-branch main
```

- Use `git add -p` (interactive staging) or name specific files rather than `git add .` to avoid accidentally staging `.env` or other sensitive files.
- Commit message format: `TICKET: Title` (e.g. `DP-600: Fix failing ingestion tests`)
- `--fill` auto-populates the MR title/description from the commit(s).
- If `glab mr create` reports an MR already exists, that's fine — the push still landed.
- If the user only wants to commit without opening an MR, drop the `glab mr create` line.
