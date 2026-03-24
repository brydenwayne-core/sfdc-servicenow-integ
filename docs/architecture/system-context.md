# System Context

## Purpose
Define the enterprise system boundary for the Salesforce–ServiceNow integration package and the external actors/interfaces it depends on.

## Primary Context

The package implements a Salesforce-native integration product where Salesforce manages intake and orchestration context, and ServiceNow is the downstream incident-management platform.

## Actors and Systems

- **Business users / support users (Salesforce):** create/update Cases that can trigger integration behavior.
- **Salesforce Runtime (this package):** evaluates metadata, builds payloads, performs callouts, logs outcomes.
- **ServiceNow Incident APIs:** receive incident create/update/comment/file operations.
- **Integration support operators:** monitor and triage transaction/error records.
- **Security/governance stakeholders:** control access to credentials, metadata changes, and operational visibility.

## Trust Boundaries

1. **Salesforce org boundary:** internal metadata/config, orchestration code, runtime logs.
2. **Credential boundary:** Named Credential + External Credential assets for outbound authentication.
3. **External service boundary:** ServiceNow API endpoints over HTTPS.
4. **Operational visibility boundary:** safe summaries and metadata-driven identifiers only, no raw sensitive payload persistence.

## Interface Summary

- **Inbound business event:** Case lifecycle activity.
- **Outbound integration calls:** incident create/update/comment/file sync to ServiceNow.
- **Operational feedback loop:** transaction status, error records, replay/retry workflows.

## Repository Evidence

- Runtime orchestration and client classes in `force-app/core/main/default/classes`.
- Credential and config schema assets in `force-app/config/main/default`.
- Runtime observability objects in `force-app/core/main/default/objects`.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Logical Architecture](logical-architecture.md)
- [Security Architecture](security-architecture.md)
- [Deployment Architecture](deployment-architecture.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
