# Process Flow: New Org Onboarding

## Purpose
Document formal onboarding flow for enabling a new Salesforce org in the integration package.

## Business and Governance Flow

1. Intake onboarding request with ownership, scope, and compliance requirements.
2. Confirm ServiceNow contract and assignment model.
3. Configure metadata and credentials in lower environment.
4. Validate end-to-end flows and observability readiness.
5. Promote and activate in production under change control.

## Technical Onboarding Flow

1. Create endpoint configuration and credential references.
2. Create org config and default request type mappings.
3. Create request type, routing, assignment, and field mapping metadata.
4. Set feature toggles and kill-switch defaults.
5. Run config validation and scenario tests.
6. Verify transaction/log/link objects for support readiness.

## Entry/Exit Criteria

### Entry

- Approved onboarding request.
- Named Credential/External Credential ready.
- Request type and routing decisions approved.

### Exit

- Successful integration test transactions.
- Runbook ownership acknowledged.
- Production activation approved with rollback and replay plan.

## Cross-links

- [Deployment Architecture](../architecture/deployment-architecture.md)
- [Metadata Architecture](../architecture/metadata-architecture.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
- [Use Case Register](use-case-register.md)
