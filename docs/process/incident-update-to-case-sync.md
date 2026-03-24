# Process Flow: Incident Update to Case Sync

## Purpose
Describe how downstream ServiceNow incident state or comments synchronize back to Salesforce Case context.

## Business Flow

1. ServiceNow incident changes occur (status/comment/work notes based on supported pattern).
2. Integration sync updates the linked Salesforce Case.
3. Support users confirm lifecycle alignment between systems.

## Technical Flow

1. Sync operation is initiated via configured integration path.
2. Runtime resolves link record and request semantics.
3. Response handling maps incident update fields to Case update rules.
4. Transaction record captures success/failure + classification.

## Exception Paths

- Missing `ServiceNow_Incident_Link__c` correlation.
- Field-level mapping mismatch.
- API update failure or throttling.

## Retry/Reprocessing Hooks

- Retry queueables for transient failures.
- Replay only when idempotency and eligibility requirements are met.

## Cross-links

- [Component Model](../architecture/component-model.md)
- [Observability Architecture](../architecture/observability-architecture.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
