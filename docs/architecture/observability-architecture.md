# Observability Architecture

## Purpose
Define how runtime behavior is measured, triaged, and operated.

## Observability Entities

- `Integration_Transaction__c` (primary lifecycle and execution telemetry)
- `Integration_Error__c` and `SN_Integration_Error__c` (error detail and categorization)
- `SN_Integration_Run__c` (run-level aggregation)
- `ServiceNow_Incident_Link__c` (cross-system correlation)

## Key Telemetry Dimensions

- org and business partitioning (`SalesforceOrgCode__c`, `BusinessUnit__c`),
- request semantics (`RequestType__c`, `Operation__c`),
- reliability posture (`Status__c`, `Lifecycle_State__c`, `RetryCount__c`, `Replay_Eligible__c`),
- failure taxonomy (`Failure_Class__c`, `ErrorCategory__c`, `ErrorCode__c`),
- traceability (`CorrelationId__c`, `IdempotencyKey__c`).

## Operational KPI Baseline

- success/failure rate by org + request type,
- retry rate and retry-age distribution,
- replay backlog over threshold age,
- median and P95 time-to-triage,
- recurring failure class trends.

## Support Workflow Integration

1. Detect abnormal failure/retry trend.
2. Triage by failure class and correlation identifiers.
3. Apply runbook decision tree (replay, reprocess, or escalate).
4. Record resolution and update metadata/process controls if needed.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Runbook Observability Model](../runbooks/observability-model.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Reprocessing Runbook](../runbooks/reprocessing-runbook.md)
- [Salesforce Transaction Correlation Triage](../knowledge/salesforce/ka-sf-001-transaction-correlation-triage.md)
