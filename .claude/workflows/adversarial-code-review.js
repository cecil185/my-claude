export const meta = {
  name: 'adversarial-code-review',
  description: 'Review a GitLab MR across correctness/security/architecture dimensions, then adversarially verify each finding before reporting',
  whenToUse: 'High-stakes or large MRs where a single-pass review risks false positives or missed issues. Not for routine/small MRs — use /review-mr instead.',
  phases: [
    { title: 'Gather' },
    { title: 'Review' },
    { title: 'Verify' },
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
          file: { type: 'string' },
          line: { type: 'number' },
          summary: { type: 'string' },
          failure_scenario: { type: 'string' },
          suggested_fix: { type: 'string' },
        },
        required: ['file', 'summary', 'failure_scenario'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reasoning: { type: 'string' },
  },
  required: ['refuted'],
}

phase('Gather')
const gathered = await agent(
  `Fetch GitLab MR ${args.mr} in repo ${args.repo} using glab (\`glab mr view ${args.mr} --output json\`, \`glab mr diff ${args.mr}\`). ` +
  `Find the Linear ticket referenced in the MR title/description and read it via the linear-server MCP for the intended goal. ` +
  `Then read EVERY changed file in full from the repo working tree (not just diff hunks). ` +
  `Return one text blob containing: 1) MR title/description, 2) Linear ticket goal summary, 3) full diff, 4) full content of every changed file, each clearly labeled with its file path.`,
  { label: 'gather', phase: 'Gather' }
)

phase('Review')
const DIMENSIONS = [
  {
    key: 'correctness',
    prompt: `Review ONLY for correctness bugs (logic errors, edge cases, data integrity, off-by-one, race conditions, concurrency) in this MR. Cite exact file:line for every finding.\n\n${gathered}`,
  },
  {
    key: 'security',
    prompt: `Review ONLY for security issues (injection, auth/authz gaps, secret handling, unsafe deserialization, SSRF, IAM overreach) in this MR. Cite exact file:line for every finding.\n\n${gathered}`,
  },
  {
    key: 'architecture',
    prompt: `Review ONLY for architecture/operational risk (breaking changes, missing critical tests, deployment/rollout risk, scope creep vs. this repo's existing conventions) in this MR. Cite exact file:line for every finding.\n\n${gathered}`,
  },
]

const reviewed = await pipeline(
  DIMENSIONS,
  d => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA }),
  (review, d) => (review?.findings || []).map(f => ({ ...f, dimension: d.key }))
)
const allFindings = reviewed.flat().filter(Boolean)

if (!allFindings.length) {
  log('No findings from any dimension — approve, no verification pass needed.')
  return { verdict: 'approve', findings: [] }
}

phase('Verify')
const verified = await pipeline(
  allFindings,
  f => parallel([1, 2, 3].map(() => () =>
    agent(
      `You are an adversarial skeptic reviewing a code-review finding against the actual source. Try to REFUTE it. ` +
      `If you cannot independently confirm the bug from the code shown, default to refuted=true.\n\n` +
      `Finding: ${f.summary}\nFile: ${f.file}:${f.line || ''}\nFailure scenario: ${f.failure_scenario}\n\n` +
      `Source context:\n${gathered}`,
      { label: `verify:${f.file}`, phase: 'Verify', schema: VERDICT_SCHEMA }
    )
  )),
  (votes, f) => ({ ...f, survives: votes.filter(Boolean).filter(v => !v.refuted).length >= 2 })
)
const confirmed = verified.filter(f => f.survives)

phase('Synthesize')
log(`${confirmed.length} of ${allFindings.length} findings survived adversarial verification.`)

return {
  verdict: confirmed.length ? 'request-changes' : 'approve',
  findings: confirmed.map(f => ({ file: f.file, line: f.line, summary: f.summary, fix: f.suggested_fix, dimension: f.dimension })),
}
