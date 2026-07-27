export const meta = {
  name: 'plan-judge-panel',
  description: 'Generate 3 independent candidate implementation plans for a Linear ticket from different angles, score them with a blind judge panel, and synthesize a combined plan',
  whenToUse: 'High-stakes or ambiguous tickets where a single-pass /adlc:plan risks missing a better approach. Not for routine/small tickets.',
  phases: [
    { title: 'Generate' },
    { title: 'Judge' },
    { title: 'Synthesize' },
  ],
}

const JUDGE_SCHEMA = {
  type: 'object',
  properties: {
    scores: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          plan: { type: 'string', enum: ['A', 'B', 'C'] },
          feasibility: { type: 'number' },
          convention_fit: { type: 'number' },
          risk_management: { type: 'number' },
          completeness: { type: 'number' },
          best_ideas: { type: 'string' },
        },
        required: ['plan', 'feasibility', 'convention_fit', 'risk_management', 'completeness'],
      },
    },
    strongest_plan: { type: 'string', enum: ['A', 'B', 'C'] },
  },
  required: ['scores', 'strongest_plan'],
}

phase('Generate')
const ANGLES = [
  {
    key: 'mvp',
    label: 'A',
    model: 'opus',
    prompt: `Read Linear ticket ${args.ticket} (linear-server MCP get_issue) and the relevant repo code. Write a technical implementation plan optimized for MVP-first: smallest change that satisfies the spec, defer nice-to-haves. Include: files to touch, approach, risks, test plan.`,
  },
  {
    key: 'risk',
    label: 'B',
    model: 'sonnet',
    prompt: `Read Linear ticket ${args.ticket} and the relevant repo code. Write a technical implementation plan optimized for risk-first: identify the riskiest/least-certain part of the change and address it first, and be conservative about blast radius (see this repo's CLAUDE.md worktree/scope discipline). Include: files to touch, approach, risks, test plan.`,
  },
  {
    key: 'simplicity',
    label: 'C',
    model: 'fable',
    prompt: `Read Linear ticket ${args.ticket} and the relevant repo code. Write a technical implementation plan optimized for simplicity: fewest new abstractions, maximum reuse of existing repo patterns (see this repo's CLAUDE.md style rules). Include: files to touch, approach, risks, test plan.`,
  },
]

const plans = await parallel(ANGLES.map(a => () => agent(a.prompt, { label: `plan:${a.key}`, phase: 'Generate', model: a.model })))

phase('Judge')
const judgePrompt =
  `Score these three independently-written implementation plans for the same ticket (${args.ticket}). ` +
  `You do not know which angle produced which plan — judge them blind. ` +
  `Score each 1-10 on: feasibility, fit with existing codebase conventions, risk management, completeness. ` +
  `Also name the single strongest overall plan and the best specific ideas from each of the others.\n\n` +
  `Plan A:\n${plans[0]}\n\nPlan B:\n${plans[1]}\n\nPlan C:\n${plans[2]}`

const judgments = await parallel([1, 2, 3].map(i =>
  () => agent(judgePrompt, { label: `judge:${i}`, phase: 'Judge', schema: JUDGE_SCHEMA })
))
const validJudgments = judgments.filter(Boolean)

phase('Synthesize')
const votes = { A: 0, B: 0, C: 0 }
validJudgments.forEach(j => { votes[j.strongest_plan] = (votes[j.strongest_plan] || 0) + 1 })
log(`Judge votes — A:${votes.A} B:${votes.B} C:${votes.C}`)

const synthesis = await agent(
  `Given these judge panel scores and the three candidate plans for ticket ${args.ticket}, synthesize ONE final implementation plan. ` +
  `Take the plan the judges favored most as the base, and graft in the best specific ideas the judges flagged from the other two. ` +
  `Do not just concatenate the three — produce one coherent plan that matches this repo's CLAUDE.md conventions.\n\n` +
  `Judge votes: A:${votes.A} B:${votes.B} C:${votes.C}\n` +
  `Judgments:\n${JSON.stringify(validJudgments)}\n\n` +
  `Plan A:\n${plans[0]}\n\nPlan B:\n${plans[1]}\n\nPlan C:\n${plans[2]}`,
  { label: 'synthesize', phase: 'Synthesize' }
)

return { plans, judgments: validJudgments, votes, synthesis }
