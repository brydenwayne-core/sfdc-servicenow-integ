# KA-SN-002 How Salesforce-Originated Incidents Are Created

## Purpose
Give ServiceNow support teams a concise view of how Salesforce events generate incidents in ServiceNow.

## Audience
ServiceNow support contacts, incident coordinators, and integration operators.

## Scope
End-to-end incident creation flow from Salesforce trigger to ServiceNow record creation.

## Source of Truth
- [Case Intake to Incident Creation](../../process/case-intake-to-incident-creation.md)
- [Salesforce Intake Pattern](../../architecture/salesforce-intake-pattern.md)
- [Incident Update to Case Sync](../../process/incident-update-to-case-sync.md)

## Flow Summary
1. Salesforce case event meets request type criteria.
2. Integration layer builds payload with mapped fields and correlation metadata.
3. ServiceNow API endpoint receives create request.
4. ServiceNow incident is created and returns incident identifier.
5. Correlation data is persisted for future updates and troubleshooting.

## Support Checks
- Confirm inbound request timestamp and payload shape.
- Verify incident record contains expected assignment and categorization.
- Confirm correlation ID is present for bidirectional sync.

## Escalate When
- API accepts payload but incident record is not persisted.
- Correlation values are missing or inconsistent across systems.
