---
name: combine-settings-files
description: >-
  Consolidate Claude Code settings.local.json files from workspace repositories
  into the central my-claude settings.json. Use when asked to combine settings,
  merge permissions, sync settings files, or clean up local settings.
---

# Combine Settings Files

Merge repo-level `settings.local.json` files into the central settings file, deduplicate, review for safety, then optionally clean up the sources.

## Source files

- `/Users/cecil/Code/genai/.claude/settings.local.json`
- `/Users/cecil/Code/genai/ingestion/.claude/settings.local.json`
- `/Users/cecil/Code/genai/ingestion-dags/.claude/settings.local.json`

## Target file

`/Users/cecil/Code/me/my-claude/.claude/settings.json`

## Steps

1. **Read all files** — read each source file and the target file. Skip any source that doesn't exist or is empty.

2. **Merge** — for each source, merge its contents into the target:
   - `permissions.allow` / `permissions.deny` / `permissions.ask`: append entries that aren't already present (exact string match)
   - `hooks`: merge by hook type (e.g. `PreToolUse`), append hook entries that don't duplicate an existing matcher+command pair
   - `env`: merge key-value pairs, don't overwrite existing keys
   - Ignore `enabledPlugins`, `extraKnownMarketplaces`, and any keys that are target-only concerns

3. **Deduplicate** — remove exact-duplicate entries within each array

4. **Safety review** — scan the merged target for:
   - Overly broad allow rules (e.g. `Bash(*)` without qualification)
   - Rules that grant write/delete access to sensitive paths (`~/.ssh`, `~/.aws`, `/etc`)
   - Allow rules that contradict deny rules
   - Report findings to the user

5. **Write** — save the merged target file

6. **DO NOT EDIT** source files at any point for any reason.