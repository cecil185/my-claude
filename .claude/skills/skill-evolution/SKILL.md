---
name: skill-evolution
description: >-
  Analyzes recent Claude Code conversation history and usage patterns to identify opportunities
  to create new skills or improve existing ones. Produces a prioritized list of new/updated
  skills and writes them to disk. Trigger when user says "evolve my skills", "analyze my
  usage", "improve my skills", "what skills should I add", "run skill evolution", "find skill
  gaps", or "what workflows should be automated".
model: claude-sonnet-4-6
effort: high
---

# Skill Evolution

Analyzes Claude Code session history to proactively grow and refine the skill library.

**Installed skills:** `~/.claude/skills/`
**Session history:** `~/.claude/projects/`

---

## Step 1 — Gather Usage Signals

Use `/search-conversations` (or the search-conversations skill logic) to scan recent sessions.

### 1a. Search for repeated workflows

Run parallel searches for high-value work domains:

```bash
# Run each as a separate search-conversations invocation
search: "Linear issue"
search: "sprint update"
search: "gitlab MR"
search: "terraform"
search: "datadog"
search: "airflow DAG"
search: "SQS"
search: "Kafka"
```

Look for:
- Workflows Cecil asked Claude to do manually 2+ times recently
- Tasks that took multiple back-and-forth rounds a skill could compress
- Domains not covered by any existing skill
- Follow-up corrections after invoking an existing skill ("that's not quite right", "format it like this")

### 1b. Read installed skills inventory

```bash
ls ~/.claude/skills/
```

Read each SKILL.md to understand current coverage. Cross-reference against usage patterns to identify gaps.

---

## Step 2 — Analyze & Decide

For each signal, apply this decision framework:

### Is this skill-worthy?

A workflow is a strong candidate if it meets **3+ of these**:

- [ ] Cecil has done it manually 2+ times in the last 2 weeks
- [ ] It requires 3+ tool calls or steps to complete
- [ ] It produces a consistent output format
- [ ] It has a clear trigger phrase
- [ ] A skill would save >5 min per invocation

### Does an existing skill already cover it?

If yes, ask:
- Did Cecil correct the output recently? → Improvement candidate
- Is the description too narrow, missing obvious triggers? → Description refinement
- Did Cecil add a new variation? → Extension candidate

### Prioritization

| Tier | Action | Threshold |
|---|---|---|
| High | Create or update now | 4+ criteria met, or Cecil explicitly asked |
| Medium | Log as candidate, skip today | 2–3 criteria |
| Skip | Note and do nothing | <2 criteria |

---

## Step 3 — Execute Changes

For each High-priority item:

### Creating a new skill

Write a complete `SKILL.md` to `~/.claude/skills/<skill-name>/SKILL.md`.

Follow the skill-writer conventions:
- `description` is third person, specific, includes trigger phrases
- `when_to_use` field present with trigger phrases
- Body under 300 lines
- At least one concrete example
- Complex workflows have numbered steps

### Improving an existing skill

Read the current SKILL.md, make targeted improvements:
- Add `when_to_use` if missing
- Expand trigger phrases
- Fix recurring mistakes observed in sessions
- Update stale context (team members, tool names, paths)
- Trim content that exceeds 300 lines to a reference file

---

## Step 4 — Report

After all changes, output a summary:

```
## Skill Evolution Run — YYYY-MM-DD

### Created
- `skill-name` — one sentence: what it does and why

### Updated
- `skill-name` — what changed and why

### Candidates (not acted on)
- workflow — why it's a candidate, what it needs

### No action
<one sentence if nothing changed>
```

---

## Guardrails

- Never delete sections from an existing skill without explicit approval
- Only act on patterns actually observed in session history — no hallucinated signals
- Check before creating that the skill name doesn't conflict with an existing one
- Preserve Cecil's writing style in all skill content (see `writing-style` skill)
