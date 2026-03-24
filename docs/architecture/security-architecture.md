# Security Architecture

## Purpose
Describe identity, access, data-protection, and operational security controls for the integration package.

## Security Model

### Identity and Credential Controls

- Outbound authentication is handled by Salesforce Named Credential + External Credential.
- Endpoint indirection is controlled via `SN_Endpoint_Config__mdt` and org metadata references.
- Secrets are not stored in Apex classes or runtime transaction objects.

### Access Controls

- Permission sets in `force-app/admin/main/default/permissionsets` segment admin and support capabilities.
- Metadata mutation rights are restricted to approved admin/release roles.
- Support operators receive least-privilege access for triage and reprocessing.

### Data Protection

- Runtime objects capture safe summaries and classification fields.
- Raw payload persistence is avoided to reduce PHI/PII exposure risk.
- Correlation IDs are used for traceability without storing full sensitive payloads.

### Operational Security

- Credential failures are treated as security incidents until triaged.
- Replay actions require operator controls and must respect idempotency policy.
- Kill switches are available for emergency containment.

## Threats and Controls Matrix

| Threat | Control |
| --- | --- |
| Credential compromise/misconfiguration | External Credential governance, rotation, validation runbooks |
| Unauthorized metadata change | Permission segregation + release gates |
| Sensitive data leakage in logs | Safe summary policy + field-level review |
| Replay abuse leading to duplicates | Replay eligibility + idempotency controls |

## Healthcare Governance Mapping

- Least privilege and role-based operational controls.
- Data minimization in runtime telemetry.
- Audit trail through transaction/error/run records.
- Controlled incident-response path documented in runbooks.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Access Model](access-model.md)
- [Security Compliance Review](security-compliance-review.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Failure Classification Flow](../process/failure-classification-and-triage.md)
