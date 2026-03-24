# Metadata Architecture

## Purpose
Define the metadata model, resolution sequence, and governance controls that make behavior configurable across orgs.

## Metadata Domains

1. **Org and endpoint domain**
   - `SN_Org_Config__mdt`, `SN_Endpoint_Config__mdt`
2. **Request policy domain**
   - `SN_Request_Type__mdt`, `SN_Feature_Toggle__mdt`
3. **Transformation domain**
   - `SN_Field_Mapping__mdt`, `SN_Incident_Template__mdt`
4. **Routing domain**
   - `SN_Routing_Rule__mdt`, `SN_Assignment_Target__mdt`

## Resolution Sequence

1. Resolve active org config and endpoint key.
2. Resolve request-type behavior and applicable toggles.
3. Load template and field mappings for payload composition.
4. Evaluate routing rules and assignment target fallback.
5. Emit transaction record with resolved keys for traceability.

## Governance Requirements

- Maintain lifecycle status and effective date ranges.
- Maintain documentation URL/admin notes for change traceability.
- Avoid overlapping active routes without deterministic precedence.
- Keep sample records in `force-app/sample-config` and schema in `force-app/config`.

## Metadata Quality Controls

- Pre-release config validation (`SN_ConfigValidationService`).
- Onboarding checklist completion before activating org/request records.
- Peer review for routing and mapping changes.
- Release evidence linking metadata change to process/runbook updates.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
- [Deployment Architecture](deployment-architecture.md)
- [Metadata-Driven Routing Flow](../process/metadata-driven-routing.md)
- [New Org Onboarding Flow](../process/new-org-onboarding.md)
