---
name: wiki:lint
description: >-
  Run health checks over the wiki to find inconsistencies, stale data,
  missing backlinks, coverage gaps, and candidate articles. Optionally
  performs auto-repair (impute missing data via web search, fix broken links).
  Use periodically to maintain wiki integrity.
model: claude-opus-4-6
effort: high
---

# Wiki Lint

Audit the wiki knowledge base for quality issues and opportunities, then report findings and optionally apply fixes.

## Checks to run

### 1. Structural integrity
- Articles referenced in INDEX.md that don't exist as files
- Files that exist but are missing from INDEX.md
- Broken `[[WikiLink]]` references (link target doesn't exist)
- Articles with no backlinks (orphaned nodes)
- Articles with missing or malformed frontmatter

### 2. Content quality
- Articles under 100 words (stubs needing expansion)
- Articles with no sources listed
- Raw docs in raw/INDEX.md that haven't been compiled into any wiki article
- Duplicate concepts (two articles covering the same thing under different names)

### 3. Consistency checks
- Conflicting claims between articles (scan for contradictions on key facts like version numbers, dates, performance benchmarks)
- Terminology inconsistency (same concept called different names across articles)

### 4. Coverage gaps
- Topics mentioned in multiple articles but without their own article
- Key entities (tools, frameworks, people) mentioned but not profiled
- Concepts that have sources in raw/ but no wiki article

### 5. Opportunity finder
- Interesting connections between articles that aren't yet linked
- Research directions suggested by what's missing
- Questions that the wiki is almost-but-not-quite able to answer

## Process

1. Read `wiki/INDEX.md` and all article files.
2. Run all checks above.
3. Report findings grouped by severity:
   - **Critical**: broken links, missing index entries
   - **Warning**: orphaned articles, stubs, uncompiled raw docs
   - **Opportunity**: gaps, new article candidates, suggested connections

4. If `--fix` mode: auto-repair Critical issues. For gaps that need web data, use WebSearch + WebFetch to impute missing info and write stub articles.

5. Write a `wiki/LINT.md` report with findings and suggested next steps.

## Output

Lint report with counts per severity, list of issues, and top 5 recommended next actions.
