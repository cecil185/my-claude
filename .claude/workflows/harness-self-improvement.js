export const meta = {
  name: 'harness-self-improvement',
  description: 'Audit Claude Code setup (skills, settings, automation gaps) across parallel lenses, then synthesize a prioritized punch list',
  whenToUse: 'Periodic self-review of the my-claude setup — right-sizing skills, cutting human-in-the-loop points, automation/hook coverage, long-running-task readiness. Read-only: never writes settings.json or skill files itself.',
  phases: [
    { title: 'Audit' },
    { title: 'Synthesize' },
  ],
}

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          area: { type: 'string' },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          finding: { type: 'string' },
          recommendation: { type: 'string' },
        },
        required: ['area', 'severity', 'finding', 'recommendation'],
      },
    },
  },
  required: ['findings'],
}

phase('Audit')
const LENSES = [
  {
    key: 'skill-quality',
    prompt: `Read every SKILL.md under ~/.claude/skills/*/ and any project-level .claude/skills/*/ you find under ~/Code/. For each, rate against: trigger precision (does the description fire on the right prompts without false positives?), workflow completeness (clear steps + tools named), output specificity (defines what a good response looks like), scope guard (defines what's out of scope), tool hints (names MCP servers/bash/paths), evidence requirement (forces citing files/lines over asserting). Flag skills as Strong/Needs work/Thin. Also flag any skill whose workflow is sequential agentic work that should instead be parallel Agent-tool dispatch or a Workflow script — that's a right-sizing miss, not just a quality nit. Also flag duplicate/overlapping skills (same trigger territory, redundant logic).`,
  },
  {
    key: 'automation-friction',
    prompt: `Sample the last ~15 session transcripts under ~/.claude/projects/*/*.jsonl (read a few full files). Look for: repeated permission prompts for the same read-only command pattern (candidates for settings.json autoApprovePatterns or hooks), skills/agents that stop to ask the user something the context or CLAUDE.md already answers, and manually-invoked skills that run on a predictable cadence (candidates for /schedule or a cron routine instead of manual triggering). Report concrete recurring patterns with example commands/prompts, not generalities.`,
  },
  {
    key: 'long-running-readiness',
    prompt: `Read every SKILL.md under ~/.claude/skills/*/ and any .claude/workflows/*.js scripts under ~/Code/. Flag: skills describing multi-step work with no TaskCreate/TaskUpdate tracking, skills that could run longer (deeper research, more exhaustive coverage) but cap themselves artificially, one-shot skills that would benefit from /loop or a scheduled routine, and any workflow script missing resumability considerations (e.g. no schema on agent() calls doing multi-step extraction, unnecessary parallel() barriers that could be pipeline() instead per the Workflow tool's own guidance).`,
  },
  {
    key: 'settings-safety',
    prompt: `Find and read ~/.claude/settings.json and every settings.local.json under ~/Code/. Report: 🔴 high risk (hardcoded credentials/secrets/tokens/passwords, private key paths, connection strings with embedded passwords), 🟡 medium risk (bypassPermissions/dangerouslySkipPermissions enabled, overly broad auto-approve patterns matching destructive commands, allowedTools permitting file deletion without a path guard), 🟢 good practice (env var references instead of inline secrets, profile-scoped AWS config, path-scoped auto-approvals). One block per file found.`,
  },
  {
    key: 'skill-gaps',
    prompt: `Read all existing SKILL.md files under ~/.claude/skills/*/ and this project's CLAUDE.md. Based on the repo map, vendor integrations, and recurring task types described there, identify high-value skills that are genuinely missing (not already covered by an existing skill or agent) — only flag real gaps, don't pad the list. For each, state why it would save real friction.`,
  },
]

const audited = await pipeline(
  LENSES,
  l => agent(l.prompt, { label: `audit:${l.key}`, phase: 'Audit', schema: FINDINGS_SCHEMA }),
  (result, l) => (result?.findings || []).map(f => ({ ...f, lens: l.key }))
)
const allFindings = audited.flat().filter(Boolean)

phase('Synthesize')
log(`${allFindings.length} raw findings across ${LENSES.length} lenses — deduping and prioritizing.`)

const synthesis = await agent(
  `You are synthesizing a Claude Code self-improvement audit. Below are raw findings from 5 independent lenses ` +
  `(skill-quality, automation-friction, long-running-readiness, settings-safety, skill-gaps) over the same setup. ` +
  `Dedupe overlapping findings (different lenses may have flagged the same root issue), then produce a single ` +
  `prioritized punch list ordered high severity first. For each surviving item, keep the concrete area, severity, ` +
  `and recommendation. Do NOT invent new findings. If the settings-safety lens proposed any settings.json changes, ` +
  `collect them into a single proposed diff block at the end, clearly labeled "PROPOSED SETTINGS.JSON DIFF — ` +
  `requires explicit user confirmation before writing, this workflow never writes it itself."\n\n` +
  `Raw findings:\n${JSON.stringify(allFindings)}`,
  { label: 'synthesize', phase: 'Synthesize' }
)

return { rawFindingCount: allFindings.length, report: synthesis }
