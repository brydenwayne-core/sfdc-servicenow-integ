# KA-SF-006 FAQ for Salesforce Support Analysts

## Purpose
Answer common Salesforce-side support questions for the ServiceNow integration.

## Audience
L1/L2 support analysts and new on-call staff.

## Scope
Operational FAQ covering triage ownership, replay, validation, and escalation.

## Source of Truth
- [ISS Support Analyst Runbook](../../runbooks/role-specific/iss-support-analyst-runbook.md)
- [Integration Support Runbook](../../runbooks/integration-support-runbook.md)
- [Troubleshooting Decision Tree](../../troubleshooting/troubleshooting-decision-tree.md)
- [Escalation Guidance by Issue Type](../../troubleshooting/escalation-guidance-by-issue-type.md)

## FAQ
### How do I decide whether to replay a failed transaction?
Classify the error first. Replay only after root cause is fixed and the failure category is replay-eligible.

### What identifiers must I include in escalation notes?
Case ID, transaction ID, correlation ID, error code, timestamp window, and actions already taken.

### Who owns routing issues vs credential issues?
Routing metadata issues are typically Salesforce admin/integration ownership; credential and endpoint failures may require joint Salesforce + ServiceNow coordination.

### When should I open a major incident?
When sync failures are broad, sustained, and affect critical request types or SLA commitments.

### How do I help new analysts onboard quickly?
Use this FAQ plus role-specific runbooks and walk through one successful and one failed transaction example.
