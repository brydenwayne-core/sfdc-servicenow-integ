# Integration Support Engineer Runbook

## Mission
Resolve systemic failures, restore service reliability, and drive durable remediation.

## Core responsibilities
- Investigate transport/platform/unknown failure patterns.
- Validate idempotency and replay safety controls.
- Coordinate remediation with Salesforce and ServiceNow owners.
- Produce technical root cause and prevention recommendations.

## Investigation workflow
1. Quantify failures by category, code, org, request type.
2. Determine whether failures are transient or deterministic.
3. Validate queue behavior and retry throughput.
4. Evaluate duplicate risk before recommending replay.
5. Propose and execute mitigation plan.

## Advanced diagnostics
- Compare `RetryCount__c` trend against success conversion rate.
- Analyze `Failure_Class__c` distribution for routing/idempotency anomalies.
- Check for correlation clusters around releases or credential changes.
- Validate normalized category mapping vs raw failure source.

## Recovery execution
- Use staged replay batches by org/request type.
- Halt replay when errors indicate unresolved root cause.
- Track before/after metrics for verification.

## Escalation
- Escalate SEV-1 outage control decisions to architect/application owner.
- Engage Salesforce admin for metadata corrections.
- Engage ServiceNow owner for sustained downstream 5xx/429 incidents.

## Done criteria
- Incident rate returns to baseline.
- Backlog stable and within SLA.
- Root cause documented with prevention tasks.
