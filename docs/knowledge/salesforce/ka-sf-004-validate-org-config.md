# KA-SF-004 Validate Salesforce Org Integration Configuration

## Purpose
Provide a concise checklist to validate Salesforce org readiness for ServiceNow incident sync.

## Audience
Salesforce admins, release coordinators, and integration support engineers.

## Scope
Org-level config checks for connectivity, metadata, permissions, and observability.

## Source of Truth
- [Configuring Salesforce–ServiceNow Integration](../../admin/configuring-salesforce-servicenow-integration.md)
- [Admin Management Handbook](../../admin/admin-management-handbook.md)
- [New Org Onboarding](../../process/new-org-onboarding.md)
- [Observability Model](../../runbooks/observability-model.md)

## Validation Checklist
1. Named/External Credentials are present and mapped to the right principals.
2. Custom metadata for endpoint and routing exists for the target environment.
3. Required permission sets are assigned to integration users and admins.
4. Transaction logging objects and fields are available and queryable.
5. Baseline smoke test produces successful create/update sync path.

## Common Misconfigurations
- Credential exists but principal permission mapping is missing.
- Routing metadata deployed without matching request type values.
- Permission assignments differ between lower and production orgs.

## Escalate When
- Org passes static checks but runtime callouts consistently fail.
- Security policy or secret-management constraints block remediation.
