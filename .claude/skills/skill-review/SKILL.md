---
name: claude-code-effectiveness
description: >-
  Assess effectiveness of Claude Code usage, evaluate skill quality, suggest
  new skills to add, review settings.local.json files for safety issues, and
  update settings.json with improvements. Use when asked to evaluate how well
  Claude Code is being used, review Claude config files, audit skills, or
  improve the my-claude setup.
---

# Claude Code Effectiveness Review

A self-improvement skill: assess how well Claude Code is being used, audit
existing skills and settings, and apply improvements directly to the
`my-claude` repo.

---

## Workflow

### Step 1 — Gather Context

Run these reads in parallel:

```bash
# Read all skill files
ls ~/.claude/skills/ 2>/dev/null || ls ~/Code/me/my-claude/.claude/skills/
cat ~/Code/me/my-claude/.claude/settings.json
find ~/Code/me/my-claude -name "settings.local.json" 2>/dev/null
find ~/Code/me/my-claude -name "CLAUDE.md" 2>/dev/null
```

Read each skill file found. Read each `settings.local.json` found.
Also read `~/.claude/settings.json` if it differs from the repo copy.

---

### Step 2 — Skill Quality Assessment

For each skill file found, evaluate against these criteria:

| Criterion | What to check |
|---|---|
| **Trigger precision** | Is the `description` specific enough to fire on the right prompts without false positives? |
| **Workflow completeness** | Does it tell Claude *what to do*, in what order, with what tools? |
| **Output specificity** | Does it define what a good response looks like, not just what to produce? |
| **Scope guard** | Does it define what's out of scope so Claude doesn't hallucinate coverage? |
| **Tool hints** | Does it tell Claude which MCP servers, bash commands, or file paths to use? |
| **Evidence requirement** | Does it require Claude to cite files/lines, not just assert findings? |

Rate each skill: **Strong** / **Needs work** / **Thin** (good idea, underspecified).

---

### Step 3 — Usage Pattern Assessment

Based on the skill files and CLAUDE.md content present, identify:

**What's being used well:**
- Skills that are complete and well-scoped
- Settings that reduce friction (auto-approve patterns, env config)
- CLAUDE.md entries that give Claude useful context upfront

**Gaps in skill coverage** — check whether any of these common high-value
skills are missing:

| Missing skill | Why it matters |
|---|---|
| `debug-aws-error` | You hit SCP/IAM errors repeatedly; a skill that knows your account IDs, org structure, and who to contact saves repeated lookup |
| `gitlab-ci-review` | You maintain GitLab CI pipelines; a skill that knows your job naming conventions and promotion order would catch regressions |
| `linear-ticket-update` | You reference Linear tickets often but updating them requires switching context |
| `slack-escalation` | You draft Slack messages to infra contacts frequently (Jeffrey Hamlin, Angelo Pace); a skill that knows the right people for the right problem |
| `schema-registry-workflow` | Avro schema work is a recurring task; encoding the registration steps and compatibility rules would speed it up |
| `production-readiness-check` | Walkthrough the Notion checklist against a repo — you started this but didn't finish |
| `blog-post-writer` | You write technical blog posts; encoding your voice and structure would make drafts faster |

Only flag the ones that are actually missing from the skills directory.

---

### Step 4 — settings.local.json Safety Review

For each `settings.local.json` found, check for:

**🔴 High risk — report immediately:**
- Hardcoded AWS credentials (`aws_access_key_id`, `aws_secret_access_key`, `AWS_SESSION_TOKEN`)
- Any `*_KEY`, `*_SECRET`, `*_TOKEN`, `*_PASSWORD`, `*_CREDENTIAL` values that are not empty or placeholder strings
- Absolute paths to private keys or cert files
- Database connection strings with embedded passwords

**🟡 Medium risk — flag and recommend:**
- `bypassPermissions: true` or `defaultMode: "bypassPermissions"` — confirm this is intentional
- `dangerouslySkipPermissions` set to true
- Auto-approve patterns that are overly broad (e.g., matching `rm -rf` or `drop table`)
- Any `allowedTools` that includes file deletion without a path guard

**🟢 Fine — note as good practice:**
- Using env var references (`${VAR_NAME}`) rather than inline secrets
- Profile-based AWS config (`profile: "datalake-stg"`)
- Path-scoped auto-approvals

Output format for this section:

```
settings.local.json — [path]
  🔴 [finding]
  🟡 [finding]
  🟢 [finding]
  No issues found (if clean)
```

---

### Step 5 — Settings Improvements

Read `~/Code/me/my-claude/.claude/settings.json` (or create it if missing).

Based on findings, propose additions. Common high-value additions for your
workflow:

```jsonc
{
  // Reduces prompting friction for common read-only operations
  "autoApprovePatterns": [
    "Bash(aws sts get-caller-identity*)",
    "Bash(aws glue list-registries*)",
    "Bash(git log*)",
    "Bash(git diff*)",
    "Bash(cat *)",
    "Bash(ls *)"
  ],

  // Keeps Claude aware of your AWS profile
  "env": {
    "AWS_PROFILE": "datalake-stg"
  }
}
```

Before writing, show the proposed additions and ask: **"Apply these to
settings.json? (y/n)"**

If confirmed, write the file using:

```bash
# Read current, merge additions, write back
cat ~/Code/me/my-claude/.claude/settings.json
```

Then write the updated JSON. Do not remove existing keys — only add or extend.

---

## Output Format

```
## Claude Code Effectiveness Review
Date: [today]

### Skill Inventory
[table: skill name | rating | top issue]

### New Skills Recommended
[list only skills not already present]

### settings.local.json Safety Report
[per-file findings]

### settings.json Proposed Updates
[JSON diff / additions]
[prompt for confirmation before writing]

### Summary
[2-3 sentence plain-language verdict on current setup quality]
```

---

## Skill Design Criteria

When evaluating or creating skills, apply this decision framework:

### Skill vs Agent

| Use a skill when... | Use an agent (Agent tool dispatch) when... |
|---|---|
| Workflow is linear — clear steps, one context | Work spans 2+ repos or domains and can run in parallel |
| Knowledge is static (key files, conventions) | Depth per domain would exhaust main context window |
| Output is a single artifact | Results need to be synthesized from independent sub-findings |
| No parallelism needed | Sequential reads would produce shallow coverage |

**Red flag:** Any skill that says "use subagents for breadth" in a footnote but structures the workflow as sequential reads is mis-classified. The subagent dispatch should be the primary step, not a footnote.

### Content Placement: Skill vs CLAUDE.md

| Put in CLAUDE.md when... | Put in skill when... |
|---|---|
| Useful in every session (architecture, data flow, repo map) | Only needed when explicitly invoked |
| Orientation-level context | Deep-dive, code-level walkthroughs |
| Static facts that don't change per task | Procedural instructions with decision logic |

**Red flag:** A skill whose first section is purely static documentation (diagrams, tables, repo maps) should have that content moved to CLAUDE.md.

### Known Improvements Applied (reference for next review)

These issues were identified and fixed — use this list to verify they haven't regressed:

| Issue | File | Fix Applied |
|---|---|---|
| `architecture-assessment` ran sequential reads instead of parallel agent dispatch | `skills/architecture-assessment/SKILL.md` | Restructured workflow: step 2 is now explicit parallel agent dispatch with example pattern; removed "use subagents" footnote |
| `system-explainer` contained static orientation content (data flow diagram, repo map, vendor table, deployment model) that should be in CLAUDE.md | `skills/system-explainer/SKILL.md` + `CLAUDE.md` | Static content moved to `CLAUDE.md` under "# System Architecture"; skill scoped to code-level deep-dives only |
| `lakehouse-query` had hardcoded ALB hostname in skill file and Python snippet | `skills/lakehouse-query/SKILL.md` + `settings.json` | Replaced with `os.environ['ONEHOUSE_HOST']`; actual value stored in `settings.json` env block |
| `review-mr` duplicates `adlc:code-reviewer` agent | `skills/review-mr/SKILL.md` | Not yet fixed — skill should delegate to `adlc:code-reviewer` and add only project-specific context |
| `ai-effectiveness-review` partially overlaps `flywheel:analyze` | `skills/ai-effectiveness-review/SKILL.md` | Not yet fixed — should call `flywheel:analyze` as a sub-step for session pattern analysis |
| No `slack-message` skill despite frequent Slack drafting | — | Created `skills/slack-message/SKILL.md` |

### High-Value Missing Skills (still to build)

| Skill | Why |
|---|---|
| `gitlab-ci-review` | Complex multi-repo CI pipelines; no automated review skill |
| `schema-registry-workflow` | Avro/Glue schema operations are recurring; encoding registration steps + compatibility rules would reduce friction |
| `debug-aws-error` | SSO expiry and IAM/SCP errors are a repeated friction point; CLAUDE.md calls this out explicitly |

---

## Scope

**In scope:** any `settings.local.json` files in `~/Code/`
