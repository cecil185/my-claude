Identify stale work across GitLab and Linear.
GitLab MRs — repo: https://gitlab.com/groups/teamworksdev/performance/data-gen-ai/ingestion/-/merge_requests

Pull all open MRs older than 7 days
Flag as stale if: no commits or comments in the last 7 days
Linear tickets — filter: project ([https://linear.app/teamworks/team/DP](https://linear.app/teamworks/team/DP/all)) status is Todo or In Progress, unchanged for 7 days

If no comments or status changes in the last 7 days
For each MR and linear ticket above, determine owner and then if an person on my team has any stale MRs or stale Linear tickets, send them one slack message with this template:

Ai-generated message:
Hey [name] 👋 Friendly reminder that these have had no activity for 7+ days — consider closing MRs and updating/closing Linear tickets.

- [MR title] — [MR URL]
- [Ticket ID]: [Ticket title] — [Linear URL]