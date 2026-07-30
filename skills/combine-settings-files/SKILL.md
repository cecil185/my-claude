---
name: combine-settings-files
description: >-
  Consolidates Claude Code settings.local.json files from workspace repositories
  into the central my-claude settings.json. Trigger when user says "combine settings",
  "merge permissions", "sync settings files", "clean up local settings", "consolidate
  my settings", or "move permissions to the central file".
model: sonnet
effort: low
disable-model-invocation: true
---

# Combine Settings Files

Merge repo-level `settings.local.json` files into the central settings file, deduplicate, review for safety, then optionally clean up the sources.

## Files

- **Sources** — every `.claude/settings.local.json` under `/Users/cecil/Code`, excluding the target repo (`me/my-claude`). Discover them rather than assuming a fixed list.
- **Target** — `/Users/cecil/Code/me/my-claude/.claude/settings.json`

## Steps

1. **Discover and read** — find the source files with `find /Users/cecil/Code -name settings.local.json -path '*/.claude/*' -not -path '*/me/my-claude/*'`, then read each one plus the target. Skip any source that is empty. Report the list of sources found before merging.

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

6. **Clean up sources** — for each source file that existed and was merged, truncate it to `{}` (empty JSON object). Do not delete the files.