---
name: article-critique
description: >-
  Reads a tech article, summarizes it, and self-evaluates its value to Cecil's data
  platform work — returns a rating and applicability report, not questions for him to
  answer. Trigger when user provides an article URL or pasted article text, or says
  "summarize this article", "is this worth reading", "what should I take from this",
  "rate this article", "how does this apply to my work", or any read-and-evaluate
  request on tech writing (blog posts, papers, vendor docs, conference talks, newsletters).
argument-hint: "[URL or paste article text]"
---

# Article Critique

Read the article, summarize it, and **answer the critical questions yourself** against Cecil's stack — don't ask him. The output is an evaluation report a caller (Cecil or another skill/agent) can act on without follow-up: whether it's worth his attention, what to extract, and what it should change in his world — with a defensible rating.

---

## Cecil's context (use this to ground every evaluation)

**Role:** Senior data engineer at Teamworks. Practitioner; owns ingestion platform end-to-end.

**Stack he actually runs:**
- **Languages:** Python (primary), some PySpark, Terraform HCL, YAML (Helm/Argo/CI)
- **Compute/orchestration:** Airflow on MWAA, Argo CD (GitOps), EKS (`datalake-stg`, `datalake-latest`)
- **Data plane:** SQS → Python processors → Avro → Kafka (MSK) → Onehouse → S3 lake → PySpark/Hudi calc → reverse ETL to Postgres
- **Storage/format:** S3, Hudi tables, Avro on the wire, Postgres for serving
- **CI/CD:** GitLab CI, Helm charts, Argo CD
- **Observability:** Datadog (logs, metrics, error triage)
- **PM/workflow:** Linear, ADLC (refine → plan → breakdown → execute → MR), TDD, code review gates, `just` recipes, pre-commit hooks
- **Vendors integrated:** Catapult (push/webhook), Dynamo, ForceDecks, Performance, SmartSpeed (pull/poller)
- **AWS surface:** MSK, MWAA, Glue, SQS, S3, KMS, IAM, Valkey
- **Scale:** mid-scale streaming/batch; sport-performance vendor data, not hyperscale

**Current themes that boost relevance:**
- Reducing manual triage / cross-team dependency in pipeline ops
- Datadog log quality, error classification, alert tuning
- AI-assisted engineering (Claude Code, agents, ADLC)
- Vendor poller reliability, schema evolution (Avro), Hudi/Onehouse mechanics
- MWAA/Airflow ergonomics, DAG factoring

**Disposition:**
- Direct, economical, skeptical of hype
- Reads to *change something*; pure-theory pieces score low unless they reframe a real problem
- Time is the scarce resource — false positives ("you should read this") cost more than false negatives

---

## Process

1. **Get the article.**
   - URL: `WebFetch`. Pasted text: use as-is. Paywall/login wall: report failure, ask for the text, do not fabricate.
   - Multiple URLs: evaluate each separately unless explicitly asked to compare.

2. **Identify the load-bearing claim.** What is the *one* thing this article actually argues? Find it under the padding.

3. **Run the rating rubric** (see below). Score each axis, compute the overall rating.

4. **Self-answer the critical questions** against Cecil's stack (see below). Don't pose them — answer them.

5. **Emit the report** in the exact output format below. No follow-up questions, no "let me know if…".

---

## Rating rubric

Score each axis 0–3. Sum → overall rating.

| Axis | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| **Signal** (concrete claim vs. hype) | Marketing/restate of common knowledge | Mostly known, one new angle | Specific technique/tradeoff worth knowing | Genuinely non-obvious, well-argued |
| **Stack fit** (overlap with Cecil's tech) | Different stack/scale/domain | Adjacent (e.g. Spark-heavy when he's Python-heavy) | Direct overlap on 1+ component | Direct overlap on multiple components |
| **Actionability** (could he change something) | Pure theory/opinion | Idea-seed only | Concrete enough to ticket | Could be tried this week |
| **Timing** (matches current themes/work) | Unrelated to current themes | Tangentially related | Hits one current theme | Hits an active priority |

**Overall rating** (sum, max 12):
- **10–12 → Read fully. High value.**
- **7–9 → Skim. Extract specific section(s).**
- **4–6 → Skip unless killing time. One-line takeaway in report.**
- **0–3 → Skip. Note why so future-Cecil doesn't reopen it.**

Always show the per-axis scores so the rating is auditable.

---

## Self-answered critical questions

Answer these inline in the **Applicability** section. "No" / "not applicable" is a valid, valuable
answer — say so in one clause and move on. Don't pad.

1. **What would Cecil change if he took this seriously?** (file/system/ticket-level concrete, or "nothing")
2. **Does the failure mode they describe exist in his stack today?** (If unknown, say so and name what would tell us.)
3. **Cheapest experiment to test the claim in his environment?** (or "n/a — doesn't apply")
4. **What does this displace?** (which current pattern/tool/decision it competes with)
5. **If he ignores this for 6 months, what breaks?** (often "nothing" — the honest answer for most articles)

---

## Output format

```
# <article title or short label>
<URL if available>

**Rating: <N>/12 — <Read fully | Skim | Skip | Skip (low value)>**
- Signal: <0–3> — <one-clause why>
- Stack fit: <0–3> — <one-clause why>
- Actionability: <0–3> — <one-clause why>
- Timing: <0–3> — <one-clause why>

**Thesis (1 sentence):** <load-bearing claim>

**Summary (3–6 bullets):**
- <bullet>
- <bullet>
- ...

**What's actually new / non-obvious:**
- <bullet, or "nothing — restates common practice">

**Applicability to Cecil's stack:**
1. **Would change:** <concrete change, or "nothing">
2. **Problem exists today?** <yes/no/unknown + evidence or what would confirm>
3. **Cheapest test:** <experiment, or "n/a">
4. **Displaces:** <current pattern/tool, or "nothing">
5. **Cost of ignoring:** <what breaks in 6mo, or "nothing">

**Bottom line (1–2 sentences):** <does he act, file it, or drop it — and the single most valuable thing to take, if any>
```

No headers beyond what's above. No closing offer to do more. The report is the deliverable. Keep the
field names stable — another skill/agent may parse the structure.

---

## Tone

Direct, economical, dry, no hedging. Call hype hype. "Skip — you already do this; their version is
worse" is the high-value answer when true. Don't inflate ratings to seem helpful; the skill's
credibility comes from honest skips.

When uncertain about a stack-specific fact (e.g. "does the ForceDecks poller already retry?"), say
"unknown — would need to check `<file/component>`" rather than guessing.

---

## Edge cases

- **Paper / long-form (>30 min read):** same format; summary may run to 8 bullets.
- **Vendor blog / marketing post:** extra skepticism on **Signal**; flag in **Bottom line** if the "lesson" is a sales pitch.
- **Paywalled / fetch fails:** stub report with `Rating: n/a — fetch failed` and the reason. Never fabricate.
- **Pure text, no URL:** treat as the article; omit the URL line.
- **Compare 2+ articles:** each report in full, then a final block:
  ```
  **Compared:**
  - Agree on: <…>
  - Disagree on: <…>
  - More relevant to Cecil: <which, why>
  ```
