# MR Body — Examples

> **Word limit: 0–2 sentences.** Default is no body. Add one only when the why is non-obvious from the title.

---

## When to write a body

- The change is risky or has non-obvious side effects
- There's a decision that reviewers might question
- There's a dependency or prerequisite the reviewer needs to know

## When NOT to write a body

- Routine feature, fix, or chore where the title is self-explanatory
- The Linear ticket already has the context

---

## Examples

### Risky change — state the risk
```
Switching from upsert to update requires maintaining TWRN↔zelus_player_id mappings outside of Axle (in GCS/BQ).
```

### Phased approach — explain the why
```
Phase 1 only: serves game data scoped to players within an AMS org. Full per-user permission enforcement is Phase 2.
```

### Dependency callout
```
Blocked on Sportlogiq API production release (expected July 6th) — deploy steps will follow once unblocked.
```

---

## Never
- "This MR adds X" — redundant with the title
- Multi-paragraph explanations for routine changes
- Restating what the diff already shows
