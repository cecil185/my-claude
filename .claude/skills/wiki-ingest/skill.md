---
name: wiki:ingest
description: >-
  Fetch web content (articles, papers, repos, pages) and save as structured
  markdown to the raw/ directory. Use when given URLs or topics to research
  and ingest into a local wiki knowledge base. Handles single URLs, batches,
  or topic-driven discovery searches.
model: claude-opus-4-6
effort: high
---

# Wiki Ingest

Fetch source material from the web and save it as clean markdown into the `raw/` directory of a wiki project. Each saved file becomes a first-class source document.

## Process

1. **Discover sources**: If given a topic rather than URLs, run 3–5 WebSearch queries to find the best 10–15 sources (papers, blog posts, docs, repos). Prioritize primary sources, authoritative blogs, and recent content (<2 years).

2. **Fetch each source**: Use WebFetch on each URL. Extract the main content — strip navigation, ads, and boilerplate. Preserve code blocks, tables, and images references.

3. **Save to raw/**: For each source, write a file to `raw/<slug>.md` with this frontmatter:
   ```markdown
   ---
   title: <page title>
   url: <source url>
   fetched: <YYYY-MM-DD>
   type: <article|paper|repo|docs|video-transcript>
   tags: [<topic1>, <topic2>]
   ---
   
   <cleaned main content>
   ```
   Slug should be kebab-case derived from the title, max 60 chars.

4. **Update raw index**: Append a one-line entry to `raw/INDEX.md` (create if missing):
   `- [<title>](raw/<slug>.md) — <one-sentence summary> (<source domain>)`

5. **Report**: List all saved files with their titles and source URLs. Note any fetches that failed.

## Rules

- Never save duplicate URLs (check INDEX.md first).
- If a page is a GitHub repo, extract the README plus any linked architecture docs.
- Preserve original structure (headings, lists, code) — do not summarize at this stage.
- If images are referenced, note them in a `<!-- images: -->` comment at the bottom.
- Max 4000 words per raw file — if longer, split into `<slug>-part-1.md`, `<slug>-part-2.md`.

## Output

Short report: files saved, files skipped (duplicate/error), total raw/ count.
