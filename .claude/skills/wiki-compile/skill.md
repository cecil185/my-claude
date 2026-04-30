---
name: wiki:compile
description: >-
  Read all documents in raw/ and compile or incrementally update a structured
  wiki in wiki/. Creates concept articles, tool profiles, summaries, backlinks,
  and a master index. Use after wiki:ingest to build or refresh the wiki from
  source material.
model: claude-opus-4-6
effort: high
---

# Wiki Compile

Process all raw source documents and maintain a structured, interlinked wiki directory. The LLM owns all wiki content — humans rarely edit it directly.

## Process

1. **Read the current state**: Read `raw/INDEX.md` and `wiki/INDEX.md` (if exists) to understand what's new since the last compile.

2. **Extract concepts and entities**: From all new/changed raw docs, identify:
   - Core concepts (frameworks, patterns, algorithms, tools, architectures)
   - People and organizations
   - Key comparisons and tradeoffs

3. **Create or update concept articles** in `wiki/concepts/<slug>.md`:
   ```markdown
   ---
   title: <Concept Name>
   updated: <YYYY-MM-DD>
   sources: [raw/<slug>.md, ...]
   related: [[[Other Concept]], ...]
   ---
   
   ## Summary
   2–3 sentence definition for skimming.
   
   ## Details
   Thorough explanation synthesized across all sources.
   
   ## Tradeoffs / When to use
   
   ## Key tools / implementations
   
   ## Sources
   - [Title](../raw/slug.md)
   ```

4. **Create or update tool profiles** in `wiki/tools/<slug>.md`:
   Same structure as concepts but with: Purpose, Architecture, Strengths, Weaknesses, Comparison to alternatives.

5. **Add backlinks**: At the bottom of each concept/tool file, list `## Referenced by` pointing to other wiki articles that link to it.

6. **Update master index** at `wiki/INDEX.md`:
   - Section per category (Concepts, Tools, Architectures, People)
   - Each entry: `- [[Article Title]] — one-line hook`
   - Keep alphabetical within sections

7. **Write a brief summary file** `wiki/SUMMARY.md`:
   - Total article count, word count estimate
   - Top 5 most-referenced concepts
   - 3–5 suggested next research directions based on gaps

## Rules

- Use `[[WikiLink]]` syntax for internal links (Obsidian-compatible).
- Never delete existing wiki content — only extend or correct it.
- If two raw sources conflict, note both views with attribution.
- Concepts should be evergreen — no time-sensitive language.
- Keep articles focused: one concept per file, no megadocs.

## Output

Summary: articles created, articles updated, backlinks added, gaps identified.
