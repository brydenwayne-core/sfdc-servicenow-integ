# KA-SF-001 Transaction Correlation Triage

## Purpose
Provide a quick reference for correlating Salesforce records with integration transaction history.

## Audience
Salesforce support analysts and integration operators.

## Scope
Lookup flow for `Case`, `Integration_Transaction__c`, and `ServiceNow_Incident_Link__c`.

## Related Documents
- [Integration Support Runbook](../../runbooks/integration-support-runbook.md)
- [Troubleshooting Patterns](../../troubleshooting/incident-sync-failure-patterns.md)

## Operational Notes
- Always capture correlation ID and request type in incident notes.

## Revision Considerations
- Keep object and field references synchronized with metadata changes.

## Core Content

1. Locate the impacted `Case` and capture record ID.
2. Query related `Integration_Transaction__c` records by source record ID.
3. Capture `CorrelationId__c`, `Status__c`, `ErrorCode__c`, and `RetryCount__c`.
4. Validate whether a `ServiceNow_Incident_Link__c` record exists.
5. Route to replay or escalation based on runbook guidance.
