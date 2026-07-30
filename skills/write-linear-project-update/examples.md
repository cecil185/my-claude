# Linear Project Update — Real Examples

Source: Cecil Ash's project updates on "Hockey Intelligence Connector to Data Platform" and "Axle ID Sync"

---

## Example 1 — Structured with headers (May 20, 2026)

```
## Completed this week

* Spike: DP-888
* Confirmed internal-only source boundary (Hockey Intelligence team, not a third-party vendor)
* Confirmed delivery mechanism: polling against the Hockey API, data via signed S3 URLs, incremental via `since` / game ID cursor
* Confirmed game-level permissioning model and identified AMS tenant → Sportlogiq org ID mapping as a dependency
* Full implementation breakdown created: Design, Build, and Validate & Deploy epics

## In flight

* Data contract finalization with Hockey Intelligence team (due from them today)
* Transformation definition + golden test dataset (with @brandonyach, no target date yet)

## Blockers / dependencies

* Hockey API available internally: **May 30** (Hockey team)
* Data contract: **due today** (Hockey team)
* AMS tenant → Sportlogiq org ID mapping ownership TBD

## Up next

Design epic tickets
```

**What to note:** Uses `## headers` for sections, bolds dates and key terms, names owners inline, explicit "due today" vs "no target date yet."

---

## Example 2 — Mixed prose + bullets, flags risk (Jun 10, 2026)

```
Design phase complete

* Data contract with Sportlogiq finalized
* Permissioning design done - agreed that each AMS customer will get all available data from Sportlogiq

Build phase well underway. The following is operational in stage:

* ingestion poller, processor
* bronze-silver transformation queries
* Airflow/Argo wiring

Focus next week:

* Transformations from silver into ams_event_value tables
* Test all components end-to-end in stage environment

Expecting to meet deadline of having Sportlogiq data available in production datalake ams_event tables by June 30th.

Riskiest part about launching this MVP will be the player ID mapping - planning to use a custom form rather than integration manager to save time.
```

**What to note:** No headers — uses bold-free section leads. States risk plainly. "Riskiest part" called out explicitly with mitigation.

---

## Example 3 — Simple Progress / Still to do (Jun 24, 2026)

```
Progress:

* Time-on-ice metrics ingested from game_context endpoint and added to game_calcs and ams_event tables
* player_info polling is implemented but not merging to production now as it is not needed for initial MVP since we decided to export a spreadsheet of players directly from Sportlogiq
* All Airflow DAGs updated for sportlogiq pipeline
* AMS event refactor completed
* All sportlogiq fields and calcs added to ams_event

Still to do:

* End-to-end test in stage environment
* Deploy to prod
* End-to-end test in prod - blocked by Sportlogiq API production release expected July 6th
* Hand-off to Laszlo for Cecil's 2-week PTO
```

**What to note:** Dead-simple format, no headers. "Blocked by" named inline with a date. Hand-off included as a task item.

---

## Example 4 — Risk + phased approach (May 29, 2026)

```
Design phase underway. Pipeline architecture doc in progress.

Risk: Sportlogiq's permission model is user-level, which requires new development in both AMS (Integrations Manager) and Sportlogiq (new API endpoint to expose the permission table). To de-risk the MVP, we're proposing a phased approach:

- Phase 1 (MVP): Serve game data scoped to players within an AMS org — no per-user permission enforcement
- Phase 2 (post-MVP): Full Sportlogiq permission model

Still waiting on Sportlogiq confirmation that Phase 1 works for them — this is a blocker for finalizing the MVP scope.
```

**What to note:** Leads with "Risk:" directly. Explains the why behind phased approach. "Blocker for finalizing" — doesn't sugarcoat dependencies.

---

## Example 5 — Minimal one-liner (Aug 2025)

```
Still need to deploy to production environment - delaying this work as it's not necessary to do in Q3
```

**What to note:** Sometimes one sentence is the whole update. No ceremony.

---

## Pattern Summary

- **Section labels vary:** sometimes `## headers`, sometimes just `Progress:` / `Still to do:` / `Focus next week:` as plain text labels
- **Blockers name owner + date:** "blocked by Sportlogiq API production release expected July 6th"
- **Risk is named plainly:** "Riskiest part about launching..." — not buried
- **No status emoji used** in these examples (added by the skill as optional)
- **Word count:** 80–180 words in substantive updates; can be 1 sentence for a quick note
