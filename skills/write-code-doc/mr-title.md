# MR Title — Examples

> **Word limit: 1 line.** The title IS the description — no body needed unless non-obvious.

Format: `type(TICKET): short imperative label`

---

## Examples

### Feature
```
feat(DP-813): no-op detection — skip tables with zero new commits
```
**What to note:** Label describes the behaviour change, not the implementation. Em dash for "which means".

---

### Chore / infra
```
DP-1318 chore: add SportLogiQ pipeline architecture & design doc
```
```
DP-1496: create argo apps for sportlogiq PROD
DP-1496: create helm charts for sportlogiq PROD
```
**What to note:** Type prefix optional for chores. Related MRs share the same ticket ID.

---

### Fix
```
DP-1660 Fix uncaught exceptions shipping as 20+ status:error log lines
```
**What to note:** Blast radius in the label — "20+ status:error log lines" tells reviewers how bad it was.

---

### Release
```
release: add comment to sportlogiq flow yamls for release to prod
```
**What to note:** `release:` prefix, no ticket needed.

---

### Untracked / cleanup
```
DP-00 delete player_info flow
```
**What to note:** `DP-00` for untracked work. Verb + object. No explanation if the context is obvious.

---

## Never
- "This MR adds..." — the label already says what it adds
- Multi-word type prefixes or nested scopes: `feat(ingestion/sportlogiq):`
