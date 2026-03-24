# KA-SN-001 Endpoint Authentication Failure Triage

## Purpose
Provide a quick triage flow for ServiceNow endpoint authentication failures observed from Salesforce.

## Audience
Integration operators, Salesforce admins, and ServiceNow support teams.

## Scope
Authentication and endpoint-configuration checks across Salesforce credential metadata and ServiceNow API connectivity.

## Related Documents
- [Admin Configuration Guide](../../admin/configuring-salesforce-servicenow-integration.md)
- [Troubleshooting Patterns](../../troubleshooting/incident-sync-failure-patterns.md)

## Operational Notes
- Authentication errors should trigger immediate credential validation and controlled replay only after remediation.

## Revision Considerations
- Revalidate against ServiceNow auth policy updates and certificate changes.

## Core Content

1. Confirm current `SN_Endpoint_Config__mdt` record points to the correct Named Credential.
2. Verify External Credential principal mapping and permission assignments.
3. Validate ServiceNow API user status and token/session validity.
4. Run a controlled test transaction in a lower environment if available.
5. Replay failed transactions marked as eligible after successful credential validation.
