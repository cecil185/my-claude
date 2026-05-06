---
name: tech-digest
description: >-
  Find the latest relevant tech articles for agentic software development and
  AI for data engineering from the past 4 days. Searches Hacker News and curated
  blogs (Simon Willison, Databricks, Confluent, Towards Data Science,
  DataEngineeringWeekly). Curates 3-5 new tools/releases per category and formats
  a digest grouped by topic. Use when asked for a tech digest, latest AI tools,
  or recent data engineering news.
model: claude-opus-4-6
effort: high
---

# AI Tech Digest

Produce a curated digest of the latest agentic dev tools and data engineering AI
releases from the past 4 days.

---

## Step 1 - Search Hacker News

Calculate CUTOFF = today minus 4 days in Unix epoch seconds.
Use WebFetch to call the HN Algolia API in parallel:

- https://hn.algolia.com/api/v1/search?query=agentic+AI+agent+framework&tags=story&numericFilters=created_at_i>CUTOFF&hitsPerPage=20
- https://hn.algolia.com/api/v1/search?query=data+engineering+AI+Kafka+Spark&tags=story&numericFilters=created_at_i>CUTOFF&hitsPerPage=20

Also run WebSearch queries in parallel:
- site:news.ycombinator.com Show HN agent AI tools
- site:news.ycombinator.com Show HN data engineering AI

## Step 2 - Search curated blogs

Compute CUTOFF_DATE = today minus 4 days (YYYY-MM-DD format).
Run these WebSearch queries in parallel using after:CUTOFF_DATE operator:

- site:simonwillison.net after:CUTOFF_DATE
- site:databricks.com/blog after:CUTOFF_DATE AI agent MCP
- site:confluent.io/blog after:CUTOFF_DATE AI agent data
- site:towardsdatascience.com after:CUTOFF_DATE release tool launch
- site:dataengineeringweekly.com after:CUTOFF_DATE

## Step 3 - Fetch top results

From search results, pick 10 most relevant URLs (skip duplicates and paywalls).
Call WebFetch on each to extract: title, one-sentence summary, publish date, URL.

Relevance boost - prioritize:
- AWS, MSK/Kafka, Apache Hudi, PySpark, Airflow
- MCP (Model Context Protocol), Claude Code, Cursor, GitLab CI/CD
- New tool releases, SDKs, libraries, or major version bumps

Exclude: opinion pieces, tutorials on basics, rehashes of old announcements.

## Step 4 - Curate and categorize

Assign each article to one bucket:

Agentic Dev Tools: tools, frameworks, SDKs, or platforms for building AI agents or
coding assistants (MCP servers, agent orchestrators, IDE plugins, LLM tooling).

Data Engineering AI: tools at the intersection of AI and data pipelines
(LLM-powered ETL, vector stores, AI-native query engines, Kafka/Hudi/Spark AI).

Select 3-5 items per category. Prefer concrete releases over trend pieces.

## Step 5 - Format the digest

Use today date from context (e.g. Thursday, May 1). Output in Slack markdown:

:robot_face: *AI Tech Digest - [Day, Month Date]*

*:wrench: Agentic Dev Tools*
- *[Name]* - [what it does and why it matters, max 20 words]. URL

*:file_cabinet: Data Engineering AI*
- *[Name]* - [what it does and why it matters, max 20 words]. URL

_Sources: Hacker News, Simon Willison, Databricks, Confluent, Towards Data Science, DataEngineeringWeekly_

Name = product name not headline. URL = bare. No filler text, no intro, no outro.

## Step 6 - Post to Slack

Use the slack skill to find user Cecil Ash and post the formatted digest as a direct message.
Run the slack skill with the formatted output as input.
