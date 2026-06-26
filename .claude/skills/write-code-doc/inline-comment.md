# Inline Comments — Examples

> **Word limit: 1 line max.** If it needs two lines, the code probably needs renaming instead.

Rule: explain the **why**, never the what.

---

## Examples

```python
# skip tables with zero new commits — avoids no-op promotions
```
```python
# weeknumber duplicates week — kept for backwards compatibility with downstream consumers
```

**What to note:**
- Em dash used for "because" / "which means" — same style as prose
- States the consequence of removing it ("avoids", "kept for")
- No subject ("We skip..." → just "skip...")

---

## When to write a comment

- A hidden constraint that isn't obvious from reading the code
- A workaround for a specific bug or external limitation
- Behaviour that would surprise a reader ("why is this here?")

## When NOT to write a comment

- The code is self-explanatory from variable/function names
- You're describing what the line does, not why
- The comment would just restate the code in English

---

## Never
- `# increment counter` above `counter += 1`
- Multi-line comment blocks explaining an algorithm (extract to a function with a clear name)
- TODO comments without a ticket reference
