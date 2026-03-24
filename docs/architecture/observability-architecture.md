# Observability Architecture

## Purpose
Define observability entities, key telemetry dimensions, and operational measurement practices.

## Observability Data Model

| Entity | Role |
| --- | --- |
| `Integration_Transaction__c` | Primary processing lifecycle record |
| `Integration_Error__c` / `SN_Integration_Error__c` | Detailed error and failure context |
| `SN_Integration_Run__c` | Aggregate run/execution grouping |
| `ServiceNow_Incident_Link__c` | Cross-system identity and sync linkage |

## Key Dimensions

- Org and business partitioning (`SalesforceOrgCode__c`, `BusinessUnit__c`)
- Request semantics (`RequestType__c`, `Operation__c`)
- Reliability state (`Status__c`, `Lifecycle_State__c`, `RetryCount__c`, `Replay_Eligible__c`)
- Failure taxonomy (`Failure_Class__c`, `ErrorCategory__c`, `ErrorCode__c`)
- Traceability (`CorrelationId__c`, `IdempotencyKey__c`)

## Operational SLO/KPI Baseline

1. Success rate by org and request type.
2. Retry rate and retry-age distribution.
3. Replay backlog age and volume.
4. Median and P95 time-to-triage.
5. Repeat failure class frequency.

## Monitoring and Response Loop

1. Detect deviation from KPI thresholds.
2. Classify failures by taxonomy and affected business scope.
3. Execute runbook workflow (retry/replay/escalate).
4. Record remediation and identify config/process correction.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Runbook Observability Model](../runbooks/observability-model.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Reprocessing Runbook](../runbooks/reprocessing-runbook.md)
- [Replay and Reprocessing Flow](../process/replay-and-reprocessing.md)
