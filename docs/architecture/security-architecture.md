# Security Architecture

## Purpose
Define security controls, trust boundaries, and governance expectations for the integration package.

## Security Control Model

1. **Credential security:**
   - Use Named Credential + External Credential metadata.
   - No secrets in Apex classes or custom metadata payload fields.
2. **Access governance:**
   - Use dedicated permission sets for admin/operator/support personas.
   - Restrict modification rights for configuration metadata and operational data.
3. **Data protection:**
   - Persist safe request/response summaries only.
   - Avoid raw sensitive payload storage in transaction/error objects.
4. **Audit and traceability:**
   - Correlation and idempotency identifiers enable incident reconstruction.
   - Lifecycle and status fields provide operational audit trails.

## Threat Considerations

- Misconfigured credentials or endpoint references.
- Overprivileged users altering routing/mapping behavior.
- Sensitive details leaked in logs or support UI.
- Replay misuse causing duplicate downstream effects.

## Required Mitigations

- Config validation before go-live and during change windows.
- Security review of permission set assignments.
- Runbook-guided handling for authentication and transport failures.
- Controlled replay and retry eligibility policies.

## Healthcare Governance Alignment

- Least privilege and role segmentation.
- Data minimization in operational telemetry.
- Change traceability through governed metadata lifecycle fields.
- Standardized operational response paths.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Access Model](access-model.md)
- [Security Compliance Review](security-compliance-review.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [ServiceNow Endpoint Authentication Failure Triage](../knowledge/servicenow/ka-sn-001-endpoint-authentication-failure-triage.md)
