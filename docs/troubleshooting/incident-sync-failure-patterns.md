# Incident Sync Failure Patterns

## Purpose
Provide rapid diagnosis patterns for common Salesforce-to-ServiceNow incident synchronization failures.

## Audience
Support analysts, operators, and on-call engineers.

## Scope
Symptom-based troubleshooting for transaction failures, retries, and escalations.

## Related Documents
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Reprocessing Runbook](../runbooks/reprocessing-runbook.md)

## Operational Notes
- Start with correlation ID and transaction status before deeper analysis.
- Escalate credential, permission, or cross-system outage failures immediately.

## Revision Considerations
- Add new patterns after each high-severity incident postmortem.

## Core Content

| Symptom | Likely Cause | Diagnostic Steps | Resolution | Escalation Path |
| --- | --- | --- | --- | --- |
| `Failed` with auth-related error codes | Named Credential or External Credential misconfiguration | Validate credential metadata deployment and auth status; compare recent release changes | Correct credential config and rerun replay for eligible records | Salesforce admin + ServiceNow integration owner |
| `Retrying` state persists beyond SLA | Queue backlog or external timeout | Check async job queue depth and timeout trend in transaction logs | Reduce backlog, verify endpoint responsiveness, replay stale eligible transactions | Platform operations |
| Duplicate incident concern | Retry attempted before idempotency key evaluation completed | Review `IdempotencyKey__c`, existing link records, and request history | Stop manual retries, confirm link reconciliation, replay once with controls | Integration engineering |
| Routing mismatch | Metadata drift in request type or routing records | Compare org/request-type metadata between environments | Promote corrected metadata and validate with sample transaction | Release manager + admin |
