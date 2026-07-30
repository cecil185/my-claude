---
name: debug-aws-error
description: >-
  Diagnoses and fixes AWS errors: SSO expiry, IAM/SCP permission denials, service
  quota limits, and resource-not-found errors. Trigger when user pastes an AWS
  error, says "AWS is failing", "I'm getting an AccessDenied", "SSO expired",
  "quota exceeded", "resource not found", or any AWS CLI/SDK/Terraform operation
  returns an error code.
model: sonnet
effort: high
---

# Debug AWS Error

Systematically diagnose the error, identify root cause, and provide the exact
fix — not a general checklist.

## Out of Scope

This skill handles credential, permission, quota, and resource lookup errors.
It does NOT:
- Write or modify IAM policies or roles (escalate to platform/infra team)
- Debug application logic errors unrelated to AWS API calls
- Investigate infrastructure provisioning failures (use `adlc:platform-engineer`)

---

## Step 0 — Get the Error

If the user did not paste an error, ask:

> "Paste the full error output (including the error code and any ARNs or resource names in the message)."

Do not proceed without the actual error text.

---

## Step 1 — Classify the Error

Read the error message and identify its type, then follow the matching playbook in
[reference.md](reference.md).

| Error pattern | Playbook |
|---|---|
| `ExpiredTokenException`, `Token has expired`, `SSO session expired` | SSO Expiry |
| `AccessDenied`, `UnauthorizedOperation`, `is not authorized to perform` | IAM/SCP Denial |
| `NoCredentialsError`, `Unable to locate credentials` | Missing Credentials |
| `ThrottlingException`, `RequestLimitExceeded`, `TooManyRequestsException`, `Rate exceeded` | Throttling |
| `ServiceQuotaExceededException`, `LimitExceededException` | Quota |
| `ResourceNotFoundException`, `NoSuchBucket`, `does not exist` | Resource Not Found |
| `EndpointResolutionError`, `Could not connect to the endpoint URL` | Endpoint Error |
| Failure from a *running workload* (Lambda, ECS/EKS, Glue job, MWAA DAG) | Operational Errors (CloudWatch) |
| Other | Generic Diagnosis |

---

## Step 2 — Run the Playbook

Follow the playbook's diagnostic commands in order. Always pass `--profile datalake-stg`
explicitly (or the profile the user names) — never change the user's active AWS config.

Two constraints that apply throughout:
- Claude cannot run `aws sso login` (needs interactive browser auth) or write to
  `~/.aws/`. Those steps go to the user, prefixed with `!` so they run in their terminal.
- Permission and quota fixes are not self-service — report exactly what to escalate
  and to whom.

---

## Step 3 — Verify

Re-run the confirming command from the playbook and check the fix actually landed.
If it did not, return to Step 1 with the new error text rather than guessing at a
second fix.

---

## Output Format

Always report exactly three things — no more, no less:

1. **Root cause** — one sentence: what failed and why (e.g. "SSO session for `datalake-stg` expired", "Missing `glue:GetTable` permission on the dev Glue catalog")
2. **Fix** — exact command(s) to run, or if escalation is needed: who to contact and exactly what to tell them (action, resource ARN, role ARN, account ID)
3. **Verification** — command to confirm the fix worked

Do not list every possible cause — identify the specific one from the error text and report only that.
