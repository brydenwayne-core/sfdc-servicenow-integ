# KA-SF-003 Review Failed Integration Transactions

## Purpose
Help support analysts quickly review failed Salesforce-to-ServiceNow transactions and determine next action.

## Audience
L1/L2 Salesforce support analysts and integration operators.

## Scope
Failure triage across transaction records, error classification, replay eligibility, and escalation routing.

## Source of Truth
- [Integration Support Runbook](../../runbooks/integration-support-runbook.md)
- [Failure Classification and Triage](../../process/failure-classification-and-triage.md)
- [Incident Sync Failure Patterns](../../troubleshooting/incident-sync-failure-patterns.md)
- [Error Code Catalog](../../troubleshooting/error-code-catalog.md)

## Procedure
1. Locate failed `Integration_Transaction__c` records by case ID, correlation ID, or time window.
2. Capture `Status__c`, `ErrorCode__c`, `ErrorMessage__c`, and retry-related fields.
3. Classify the failure (configuration, auth, validation, dependency, transient).
4. Check replay policy for the failure category.
5. Replay only when the root cause is remediated and replay is explicitly allowed.

## Decision Guide
- **Replay now:** transient or dependency outage has cleared.
- **Fix config then replay:** metadata/credential/routing defects.
- **Escalate without replay:** persistent platform errors, unclear ownership, or repeated failures.

## Escalate When
- Same correlation path fails repeatedly after remediation.
- Failure category indicates cross-team dependency and no owner response.
