---
name: response-to-feedback
description: Evaluates dissenting arguments or counter-reviews in <repo>/code-review.md, formulates point-by-point rebuttals or concessions, and appends the response to the ledger in an additive-only fashion.
---

# Response to Feedback Skill (`response-to-feedback`)

## Purpose
The `response-to-feedback` skill manages multi-model debates on code reviews stored in `<repo>/code-review.md`. When a secondary model, reviewer, or human author appends counter-arguments, dissents, or feedback to the ledger, this skill reads the complete conversation history, analyzes the new arguments point-by-point, defends or concedes positions based on technical evidence, and appends a structured rebuttal to `<repo>/code-review.md`.

---

## Workflow & Protocol

### 1. Read & Contextualize Ledger
* Read the entire contents of `<repo>/code-review.md`.
* Locate the most recent entry from the opposing model/reviewer.
* Extract all specific counter-claims, dissents, or proposed counter-solutions.

### 2. Rigorous Technical Assessment
For every point raised by the opposing reviewer:
* **Defend with Proof**: If the opposing argument is incorrect or incomplete, provide concrete technical evidence, code traces, edge cases, or documentation proofs defending the original position.
* **Concede when Valid**: If the opposing argument correctly identifies a flaw or invalidates a prior critique, explicitly concede the point and document the refined consensus.
* **Counter-Challenge**: Raise new edge cases or technical implications created by the opposing reviewer's proposal.

### 3. Additive-Only Discipline
* **NEVER** edit, modify, delete, or overwrite previous review entries or turns in `code-review.md`.
* Always **append** the response entry to the end of `<repo>/code-review.md`.

---

## Output Format Specification

Appended response entries in `<repo>/code-review.md` MUST follow this exact Markdown structure:

```markdown
---
## [Debate Response Entry] - <YYYY-MM-DD HH:MM:SS TZ>
**Model / Role**: Primary Reviewer (Rebuttal & Defense)  
**Responding To**: Entry by `<Opposing_Model_or_Reviewer>`  
**Target Repository**: `<repo>`  

### 1. Debate Position Summary
A high-level statement summarizing points defended, points conceded, and current consensus status.

### 2. Point-by-Point Rebuttal Matrix

| Issue / Claim ID | Opposing Claim | Position | Technical Defense / Concession Rationale |
| :--- | :--- | :--- | :--- |
| **Claim 1** | Summary of counter-argument | [Defend / Concede / Counter] | Detailed technical justification with code references. |

### 3. Technical Evidence & Code Proofs
Provide concrete code snippets, tracebacks, or logic proofs supporting contested items:
```python
# Proof snippet or corrected implementation
```

### 4. Consensus & Remaining Disagreements
* **Agreed Items**: List of issues where both models/reviewers align.
* **Open Contested Items**: Unresolved technical points requiring human resolution or further debate turns.
```

---

## Usage Guide
1. Read the full debate history in `<repo>/code-review.md`.
2. Analyze the latest feedback or counter-argument entry.
3. Construct a point-by-point technical defense / concession.
4. Append the formatted response entry to `<repo>/code-review.md`.
