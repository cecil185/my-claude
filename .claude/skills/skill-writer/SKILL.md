---
name: skill-writer
argument-hint: "[skill-name-or-path]"
description: Writes or improves a Claude Code SKILL.md file following best practices. Reads the existing skill (if given a name or path), identifies quality issues, and produces a complete ready-to-save SKILL.md with correct frontmatter, sized under 300 lines. Use when asked to create a skill, write a slash command, improve an existing SKILL.md, or review a skill for quality issues.
when_to_use: Trigger when the user says "create a skill", "write a skill", "improve this skill", "review this SKILL.md", "make a slash command", or passes a skill name/path to audit.
---

# Skill Authoring

Produces well-structured SKILL.md files that Claude can discover and execute effectively.

---

## Frontmatter fields

All fields are optional except `description` (recommended). Use only what's needed.

```yaml
---
name: kebab-case-name          # directory name if omitted; max 64 chars, lowercase/numbers/hyphens
description: >                 # what it does + when to use it; third person; max 1024 chars
  Processes X and does Y. Use when user asks about Z or mentions W.
when_to_use: >                 # additional trigger phrases, appended to description in listing
  Trigger when user says "...", "...", or "..."
argument-hint: "[issue-number]"  # shown in autocomplete
arguments: [arg1, arg2]          # maps to $arg1, $arg2 positional substitutions
disable-model-invocation: true   # user-only invocation (deploys, commits, destructive ops)
user-invocable: false            # Claude-only (background knowledge, not a command)
allowed-tools: "Bash(git *) Read"  # pre-approved tools; space-separated
context: fork                    # run in isolated subagent
agent: Explore                   # which subagent (Explore, Plan, general-purpose, or custom)
model: claude-opus-4-7           # model override for this skill's turn
effort: high                     # low / medium / high / xhigh / max
paths: "src/**/*.py, tests/**"   # only activate when working with matching files
---
```

**String substitutions available in the body:**
- `$ARGUMENTS` — full argument string
- `$0`, `$1`, … — positional args (0-based)
- `$name` — named arg from `arguments:` list
- `${CLAUDE_SKILL_DIR}` — directory containing this SKILL.md
- `${CLAUDE_SESSION_ID}` — current session ID
- `${CLAUDE_EFFORT}` — current effort level

---

## Writing the description

The description is the discovery mechanism — Claude uses it to decide whether to load the skill.

**Rules:**
- Always third person ("Processes X", not "I can" / "You can")
- Lead with what it does, follow with when to use it
- Include exact trigger phrases users would say naturally
- Be specific: name the artifact, domain, or operation
- Combined `description` + `when_to_use` is capped at 1,536 chars in the listing

**Good:**
```yaml
description: Generates descriptive commit messages by analysing git diffs. Use when the user asks for help writing commit messages, wants to review staged changes, or says "what should I commit".
```

**Bad:**
```yaml
description: Helps with git stuff
```

---

## Sizing and structure

- **Keep SKILL.md under 300 lines.**
- Move detailed reference docs, API specs, or long examples to supporting files and reference them from SKILL.md.
- Keep references one level deep from SKILL.md — deeply nested references get partially read.
- Include a table of contents at the top of any reference file longer than 100 lines.

```
my-skill/
├── SKILL.md              # overview + navigation (required, <300 lines)
├── reference.md          # detailed docs (loaded on demand)
├── examples.md           # sample inputs/outputs (loaded on demand)
└── scripts/
    └── validate.sh       # executed, not loaded into context
```

Reference supporting files explicitly so Claude knows when to load them:

```markdown
For complete API details, see [reference.md](reference.md).
For usage examples, see [examples.md](examples.md).
```

---

## Degrees of freedom

Match specificity to the task's fragility:

| Situation | Approach |
|-----------|----------|
| Multiple valid paths, context-dependent | Text instructions with heuristics (high freedom) |
| Preferred pattern, variation acceptable | Pseudocode / parameterised template (medium freedom) |
| Fragile sequence, must not deviate | Exact commands, no parameters (low freedom) |

Use "MUST" / "ALWAYS" only for low-freedom constraints that have actually caused failures.

---

## Dynamic context injection

Use an exclamation mark followed by a shell command wrapped in backticks on its own line. The harness executes it and substitutes the output before Claude sees the skill body.

Example: a line reading `!` + `` `git diff HEAD` `` injects the current diff inline.

Multi-line commands use a fenced `!` code block (opening fence is three backticks followed by `!`).

**Caution:** Dynamic commands run in the session's working directory. Commands like `git diff HEAD` fail if the working directory is not a git repo (e.g. a workspace root containing multiple sub-repos). Guard with `2>/dev/null || echo "(no output)"` or only use dynamic injection for commands that are safe to fail.

---

## Invocation control

- `disable-model-invocation: true` — for skills with side effects (deploy, commit, send message). You invoke; Claude never auto-triggers.
- `user-invocable: false` — for background context Claude applies automatically but which isn't a meaningful command for users.

---

## Anti-patterns

- **Too many options.** Pick a default; offer one alternative for the edge case.
- **Over-explaining.** Claude already knows what a PDF is, what git does, etc. Only add context Claude doesn't have.
- **Deep nesting.** Reference files should link directly from SKILL.md, not from other reference files.

---

## Quality checklist

Before saving:

- [ ] Description is third person, specific, includes trigger phrases
- [ ] `disable-model-invocation` set correctly for destructive/side-effect workflows
- [ ] SKILL.md body under 300 lines
- [ ] At least one concrete example (not abstract)
- [ ] Supporting reference files are one level deep from SKILL.md
- [ ] Complex workflows have numbered steps and a progress checklist
- [ ] Feedback loops included for quality-critical tasks (validate → fix → repeat)

---

## Output

Produce a complete, ready-to-save SKILL.md with all frontmatter fields that are needed (and only those). End with a one-line note on where to save it: `~/.claude/skills/<name>/SKILL.md` (personal) or `.claude/skills/<name>/SKILL.md` (project).
