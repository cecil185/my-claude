---
name: writing-style
description: Cecil Ash's personal writing style guide. Use this skill whenever Cecil asks Claude to write, draft, or edit anything in his voice — including Slack messages, Notion docs, Linear tickets, blog posts, LinkedIn posts, performance reviews, technical specs, runbooks, or any other written content. Also use when he says "write this for me", "draft this", "in my style", or "make this sound like me".
---

# Cecil Ash — Writing Style Guide

Derived from: Notion docs (runbooks, spike specs, performance reviews, architecture notes), Slack messages across #team-eng-data-platform, #ai-champions, and #alerts-data-platform-merge-requests.

---

## Voice & Personality

**Direct and confident, not hedging.** Cecil states things plainly and doesn't soften hard truths with filler.
- ✅ "How do we not have perms to write in prod? I've seen no proof."
- ❌ "I was just wondering if it's possible that maybe we don't have permissions?"

**Slightly cheeky, not formal.** Dry wit surfaces in technical writing. He'll call something "brilliant" with a lightbulb emoji in Slack, or drop a casual callout note mid-runbook. Professional but never stiff.

**Practitioner voice.** Writes like someone who has done the thing, not like someone documenting it from a distance. Uses "we" for team decisions, "I" for personal ownership.

**Economical.** No padding. No "As mentioned above." No "In conclusion." Gets to the point fast and stops.

---

## Structural Patterns

### Technical Docs (Runbooks, Specs, Architecture Notes)
- **Lead with the problem or purpose** — never with background that the reader already has
- **Bold the pain point early**: "Primary pain: Both the manual iteration time AND the cross-team dependency are equally blocking us..."
- **When/Then structure** for conditional steps: `**When**: ref/ directory has changes (new/modified Avro schemas).`
- **Numbered promotion order** with explicit skip instructions: "Only promote the layers that have changes. Skip steps where no code changed since last promotion."
- Uses callout blocks (colored notes) for important caveats mid-flow
- Tables for: service maps, troubleshooting guides, automation candidates with open questions
- ASCII architecture diagrams for system flows: `Webhooks/Pollers --> SQS --> Processors --> Kafka --> Onehouse`
- Checklists (`- [ ]`) for sequential validation steps, checked off as completed
- Code blocks for: exact commands, changelog templates, config snippets

### Spike Specs / Design Docs
- **Current state → what we want → automation opportunities** — always this order
- Surfaces open questions explicitly in a table with "Open questions" column
- "Out of scope" section at the end, not the beginning
- Success criteria as checkboxes, not prose

### Slack Messages
- **Very short.** Often 1–2 sentences, sometimes just a link + context label
- Pings specific people with `@name` inline, not at the end
- Action requests are direct: "Can you please review?" not "Would you mind taking a look when you get a chance?"
- Shares MR links with a short label: `lower mwaa alert threshold` or `feat(DP-813): no-op detection — skip tables with zero new commits`
- Asks clarifying questions cleanly: "To test out my Datadog ingestion monitors, I need to release prod ingestion-processor to the latest commit on main (5ea4157)? Am I safe to do so?"

### Performance Reviews / Self-Assessments
- Leads with concrete deliverables, then the impact
- Quantifies where possible: "reduced 8 DAGs by about 350 lines each", "2 DAGs totaling 955 lines of code"
- Names the person who gave the feedback: "Tomas said that I did a great job..."
- Owns stretch work proactively: "I exceeded expectations by identifying..."
- Growth areas are honest and specific, not generic: not "I want to improve communication" but "I want to take on a larger role in guiding teams through the design process"

---

## Language Patterns

### Phrases Cecil Uses
- "I assume..." (hedging a technical claim, not an emotional one)
- "I'm not sure — I'll..." (transparent about uncertainty, immediate next action)
- "Good call out" (crediting a teammate's feedback)
- "Ok, agreed." (short acknowledgment before pivoting)
- "The most time-consuming triage step" / "equally blocking" (quantifying friction)
- "Which were the most complex that he's seen" (borrowing external credibility)
- "...for the first time" (flags net-new territory vs. SOP)
- "This is brilliant 💡" (Slack-only enthusiasm, emoji-backed)

### Phrases Cecil Avoids
- "Leverage" (never)
- "Touch base", "circle back", "synergy"
- "As per my last message"
- Passive voice on ownership: not "it was decided" but "we decided" / "I decided"
- Filler openers: "Great question!", "Certainly!", "I'd be happy to help"

---

## Formatting Conventions

| Context | Format |
|---|---|
| Slack | Plain text, 1–3 sentences, links with short labels, @mentions inline |
| Notion runbooks | H2/H3 sections, tables, checklists, code blocks, callout notes |
| Spike specs | H2 sections: Overview → Current State → What We Want → Opportunities → Questions → Success Criteria → Out of Scope |
| MR descriptions | Short label + ticket ID: `feat(DP-813): no-op detection — skip tables with zero new commits` |
| Linear tickets | Desired Outcome first, then context |
| Blog/LinkedIn | Summary-first, practitioner audience, no hype |

**Punctuation style:**
- Em dashes (—) used liberally for asides and pivots
- Parentheticals for quick context additions
- No Oxford-comma drama — he uses it naturally
- Bold used for key terms and pain points, not for decoration

---

## Tone by Context

| Context | Tone |
|---|---|
| Slack to teammates | Casual, direct, brief. Slightly dry. |
| Slack asking for help | Clear ask + why it's blocked, minimal preamble |
| Runbook/doc | Precise, imperative mood, no ambiguity |
| Spike spec | Analytical, lays out unknowns honestly, action-oriented |
| Performance review | Confident ownership, concrete evidence, genuine |
| Blog/LinkedIn | Thoughtful practitioner, not thought-leader posturing |

---

## Common Writing Tasks — Style Notes

**Slack message asking for a review:**
> `Can you please review? [link]` — one line, direct. No "when you get a chance."

**Calling out a blocker:**
> State it flat: "How do we not have perms to write in prod? I've seen no proof." Then tag the person who can resolve it.

**MR description:**
> Ticket ID + short imperative label. Optional: 1-sentence rationale if non-obvious.

**Runbook step:**
> Bold the trigger condition. List pre-checks as checkboxes. Post-validation section always follows promote section.

**Technical design doc intro:**
> Lead with the pain, not the background. The reader already has the background.