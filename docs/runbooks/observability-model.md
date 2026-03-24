# Observability Model

## Purpose
Provide operational response procedures for day-to-day support and incidents.

## Audience
Support analysts, integration operators, on-call engineers

## Scope
Operational execution steps, escalation points, and recovery controls.

## Related Documents
- [Documentation Taxonomy Standard](../architecture/documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

## Enterprise support model
`Integration_Transaction__c` is the primary support command layer.

### Recommended filters
- `SalesforceOrgCode__c`
- `RequestType__c`
- `ErrorCategory__c`
- `Failure_Class__c`
- `Status__c`
- `Lifecycle_State__c`
- `Replay_Eligible__c`

### Lifecycle model
- `Queued`
- `In Progress`
- `Retrying`
- `Succeeded`
- `Failed`
- `Abandoned`

Use `Lifecycle_State__c` to express finer-grained execution states such as routing, awaiting retry, and completed.

### Retry visibility
- `RetryCount__c`
- `Last_Retry_At__c`
- `Retry_History__c`
- `Replay_Eligible__c`

### Audit-safe logging
- Store only safe request and response summaries.
- Do not persist raw payload bodies or sensitive case text.
- Use correlation id plus idempotency key for cross-system traceability.

### Dashboard/list view recommendations
- Failed by org and failure class.
- Retrying backlog by support status.
- Replay-eligible transactions older than 30 minutes.
- Daily success/failure trend by request type.
