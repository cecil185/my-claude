# AWS Error Playbooks

One playbook per error class. All commands assume `--profile datalake-stg` unless the
user specifies otherwise.

## Contents

- [SSO Expiry](#sso-expiry)
- [IAM/SCP Denial](#iamscp-denial)
- [Missing Credentials](#missing-credentials)
- [Throttling](#throttling)
- [Quota](#quota)
- [Resource Not Found](#resource-not-found)
- [Endpoint Error](#endpoint-error)
- [Operational Errors (CloudWatch)](#operational-errors-cloudwatch)
- [Generic Diagnosis](#generic-diagnosis)

---

## SSO Expiry

**Confirm the session is expired:**
```bash
aws sts get-caller-identity --profile datalake-stg
```
If this returns `ExpiredTokenException`, the session is expired.

**Fix — user must run this in the terminal (opens a browser):**

Tell the user to run:
```
! aws sso login --profile datalake-stg
```
The `!` prefix runs it directly in their Claude Code session terminal. Claude cannot run `aws sso login` on behalf of the user because it requires interactive browser authentication.

**After the user logs in, verify:**
```bash
aws sts get-caller-identity --profile datalake-stg
```
Report the `Account`, `UserId`, and `Arn` so the user can confirm the right identity loaded.

If you don't know which profile to use:
```bash
aws configure list-profiles
```
Default to `datalake-stg` unless the user specifies otherwise.

---

## IAM/SCP Denial

**Confirm the identity first:**
```bash
aws sts get-caller-identity --profile datalake-stg
```

**Extract from the error message:**
- The action that was denied: e.g. `glue:GetTable`
- The resource ARN it was denied on: e.g. `arn:aws:glue:us-east-1:123456789:table/...`
- Example full message: `User: arn:aws:sts::123456789:assumed-role/... is not authorized to perform: glue:GetTable on resource: arn:aws:glue:...`

**Determine if it's IAM or SCP — read the full error message for these phrases:**

| Phrase in error message | Type | What it means |
|---|---|---|
| `due to an explicit deny in a service control policy` | SCP | Org-level block — cannot be fixed with IAM changes |
| `Organizations policy` or `SCP` | SCP | Same — escalate |
| `no identity-based policy allows` | IAM | Missing permission — role needs the action added |
| `explicit deny` alone (no SCP mention) | IAM explicit deny | A Deny statement in an IAM policy is blocking this |

**For IAM missing-permission denials:**
- The user cannot self-service this — they operate via SSO assumed roles
- Report: "Missing IAM permission: `{service}:{Action}` on `{resource ARN}`"
- Tell the user to raise this with the platform/infra team, including:
  - The exact action and resource ARN from the error
  - The role ARN from `sts get-caller-identity` output
  - The account ID

**For IAM explicit denials (Deny statement in a policy):**
- Same escalation path — a Deny in the policy is overriding any Allow
- Report the specific Deny that needs to be removed

**For SCP denials:**
- Do not attempt to fix — SCPs are org-level controls outside IAM
- Report: "Blocked by AWS Service Control Policy — this action is restricted at the AWS organization level and cannot be unblocked by adding IAM permissions."
- Include: exact action, resource ARN, account ID

---

## Missing Credentials

**Check what's configured:**
```bash
aws configure list --profile datalake-stg
```

**Check the environment:**
```bash
aws configure list
```
Look for `(None)` in the `access_key` row — that confirms no credentials are loaded for the current context.

**Common causes and fixes:**

| Cause | Fix |
|---|---|
| `AWS_PROFILE` not set, default profile empty | Tell user to set `AWS_PROFILE=datalake-stg` in their shell |
| Profile not found in `~/.aws/config` | The profile needs to be added — run `aws sso login --profile datalake-stg` to initialize it |
| `~/.aws/config` or `~/.aws/credentials` missing | Run `aws configure sso` to set up the profile from scratch |
| Wrong profile in use | Check `aws configure list-profiles`; switch to `datalake-stg` |

Note: Claude cannot modify `~/.aws/` files — all fixes here require the user to run commands in their terminal.

---

## Throttling

AWS throttles requests when call rate exceeds the service limit. This is usually transient.

**Identify the service and operation from the error** — e.g. `Rate exceeded` on `glue:GetTable`.

**Immediate fix options:**

1. **Wait and retry** — most throttling is transient; wait 5–30 seconds and retry
2. **Reduce parallelism** — if running concurrent calls, reduce them
3. **Check if it's sustained** — if throttling persists, it may be a quota issue (see [Quota](#quota))

**Check current throttle rates if needed:**
```bash
aws service-quotas get-service-quota \
  --service-code {service} \
  --quota-code {quota-code} \
  --profile datalake-stg
```

For Glue specifically, the default `GetTable` TPS is low (5 req/sec). If the application is calling it in a tight loop, the fix is in the application code, not AWS.

---

## Quota

**Get quota details:**
```bash
aws service-quotas list-service-quotas \
  --service-code {service} \
  --profile datalake-stg \
  --query 'Quotas[*].[QuotaName,Value,QuotaCode,Adjustable]' \
  --output table
```

Common service codes: `glue`, `sqs`, `kafka`, `eks`, `s3`, `lambda`, `ec2`.

**If you know the quota code:**
```bash
aws service-quotas get-service-quota \
  --service-code {service} \
  --quota-code {quota-code} \
  --profile datalake-stg
```

Report:
- Current limit value
- Whether the quota is `Adjustable: true/false`
- If adjustable: the fix is a Service Quotas increase request via the AWS Console at `console.aws.amazon.com/servicequotas`

If not adjustable, escalate to the platform team — some quotas require AWS Support involvement.

---

## Resource Not Found

**Check the region first:**
```bash
aws configure get region --profile datalake-stg
```

Resources in the wrong region return "not found" — the resource may exist, just not in the region being queried. Expected regions for this account: `us-east-1` or `us-east-2`.

**Verify the resource exists in the right region:**
```bash
# S3 (global — region doesn't matter for bucket listing)
aws s3 ls s3://{bucket-name} --profile datalake-stg

# Glue database/table
aws glue get-table --database-name {db} --name {table} \
  --region us-east-1 --profile datalake-stg

# SQS queue
aws sqs get-queue-url --queue-name {name} \
  --region us-east-1 --profile datalake-stg

# MSK cluster
aws kafka list-clusters --region us-east-1 --profile datalake-stg

# EKS cluster
aws eks list-clusters --region us-east-1 --profile datalake-stg
```

Report: whether the resource exists, in which region, and whether the name/ARN in the original command was wrong.

---

## Endpoint Error

**Confirm region is configured:**
```bash
aws configure get region --profile datalake-stg
```

If blank or wrong, tell the user to add `--region us-east-1` to their command. To persist the region:
- The user should run: `aws configure set region us-east-1 --profile datalake-stg` in their own terminal
- Claude cannot run this — writing to `~/.aws/` is blocked

**VPC endpoint issues:** if running inside a private subnet, traffic may route through a VPC endpoint. If the error URL looks non-standard (e.g. `vpce-xxx.s3.us-east-1.vpce.amazonaws.com`), check that the VPC endpoint policy allows the operation. This requires escalation to the platform/infra team.

---

## Operational Errors (CloudWatch)

For errors from *running workloads* (Lambda failures, ECS/EKS task crashes, Glue job failures, MWAA DAG errors), the root cause is typically in the logs, not in the API call itself.

Use the CloudWatch MCP to investigate:

```python
# Discover log groups for the service
mcp__aws-cloudwatch__describe_log_groups(
    log_group_name_prefix="/aws/{service}/{resource-name}"
)

# Query logs for the error window
mcp__aws-cloudwatch__execute_log_insights_query(
    log_group_name="/aws/{service}/{resource-name}",
    query_string="fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20",
    start_time=<epoch_seconds>,
    end_time=<epoch_seconds>
)

# Check active alarms
mcp__aws-cloudwatch__get_active_alarms()
```

Report: the specific log lines that show the failure, the timestamp, and the request ID if present.

---

## Generic Diagnosis

If the error doesn't match the patterns above:

1. Confirm auth works:
   ```bash
   aws sts get-caller-identity --profile datalake-stg
   ```
2. Re-run the original command with `--debug` to get the full HTTP exchange:
   ```bash
   {original-command} --profile datalake-stg --debug 2>&1 | tail -60
   ```
3. Extract from the debug output:
   - HTTP response status code (e.g. `HTTP/1.1 403`)
   - `x-amzn-requestid` header value — needed for AWS Support escalation
   - The full error XML/JSON body

4. Search the AWS documentation for the specific error code if unfamiliar.
