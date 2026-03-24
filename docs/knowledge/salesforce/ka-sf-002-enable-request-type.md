# KA-SF-002 Enable a Request Type for Incident Sync

## Purpose
Provide Salesforce admins with a quick procedure to enable a request type for ServiceNow incident creation.

## Audience
Salesforce admins and integration support engineers.

## Scope
Enablement steps for metadata-driven request type routing and validation checks.

## Source of Truth
- [Metadata-Driven Routing](../../process/metadata-driven-routing.md)
- [Configuring Salesforce–ServiceNow Integration](../../admin/configuring-salesforce-servicenow-integration.md)
- [Salesforce Admin Runbook](../../runbooks/role-specific/salesforce-admin-runbook.md)

## Procedure
1. Confirm the target request type and business intent with support/process owners.
2. Create or update the routing metadata entry for that request type and environment.
3. Verify required target assignment metadata is present (assignment group, category/subcategory, priority mapping if applicable).
4. Ensure the request type is active in the selected org and included in deployment scope.
5. Run a controlled test case and verify incident creation plus expected field mappings.

## Validation Checklist
- Request type resolves to the expected routing metadata.
- No validation or callout errors appear in transaction logs.
- Created incident reflects expected ownership and categorization.

## Escalate When
- Routing metadata is present but transaction still returns configuration errors.
- Incident is created with incorrect assignment despite correct metadata values.
