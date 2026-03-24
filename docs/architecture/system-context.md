# System Context

## Purpose
Define the enterprise system boundary, external dependencies, actors, and trust boundaries for the Salesforce–ServiceNow integration package.

## Scope
This document covers runtime behavior implemented in:

- `force-app/config` (metadata schema, credential references),
- `force-app/core` (orchestration, integration runtime, observability objects),
- `force-app/admin` (operator/admin access and UX),
- `force-app/sample-config` (reference onboarding records).

## Context Summary

The package is a Salesforce-native integration product that converts Salesforce Case-driven events into ServiceNow Incident API operations with metadata-governed behavior and operational telemetry.

## External Actors and Systems

| Actor / System | Role | Interface |
| --- | --- | --- |
| Business users in Salesforce | Create/update Cases that may trigger sync | Salesforce UI, Case data |
| Salesforce integration runtime | Evaluates metadata, builds payloads, executes callouts | Apex + Queueable execution |
| ServiceNow Incident APIs | Downstream incident create/update/comment/file operations | HTTPS REST endpoints |
| Integration support operators | Monitor failures, triage, replay/reprocess | Salesforce runtime objects + runbooks |
| Security architecture stakeholders | Credential governance, least-privilege policy | Named/External Credential + permission sets |

## Trust Boundaries

1. **Salesforce org boundary:** business data, configuration metadata, runtime logs.
2. **Credential boundary:** Named Credential / External Credential assets and principal mapping.
3. **External API boundary:** ServiceNow over TLS with network and auth controls.
4. **Operations boundary:** safe telemetry exposed to support with data minimization constraints.

## System Context Diagram (Textual)

1. Salesforce Case event starts orchestration.
2. Runtime resolves org/request/routing/mapping metadata.
3. Runtime calls ServiceNow via Named Credential endpoint.
4. Runtime logs transaction/error/link records.
5. Support operators use runbooks for triage/replay and escalation.

## Governance Expectations

- Controlled metadata promotion and lifecycle fields for change traceability.
- Documented support procedures for failure classes and reprocessing.
- Security review for credential and permission set posture.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Logical Architecture](logical-architecture.md)
- [Component Model](component-model.md)
- [Security Architecture](security-architecture.md)
- [Deployment Architecture](deployment-architecture.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Case Intake to Incident Creation Flow](../process/case-intake-to-incident-creation.md)
