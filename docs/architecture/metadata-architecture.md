# Metadata Architecture

## Purpose
Describe the configuration data model and governance expectations for metadata-driven behavior.

## Metadata Domains

- **Org and endpoint domain:** `SN_Org_Config__mdt`, `SN_Endpoint_Config__mdt`
- **Request policy domain:** `SN_Request_Type__mdt`, `SN_Feature_Toggle__mdt`
- **Transformation domain:** `SN_Field_Mapping__mdt`, `SN_Incident_Template__mdt`
- **Routing domain:** `SN_Routing_Rule__mdt`, `SN_Assignment_Target__mdt`

## Governance Attributes

Most metadata types include lifecycle and operational fields to support enterprise governance:

- lifecycle status,
- effective start/end dates,
- admin notes,
- documentation URL,
- active flags.

## Resolution Model

1. Identify org configuration and active endpoint.
2. Resolve request type behavior and rollout toggles.
3. Resolve mapping/template/routing records by org and key.
4. Select assignment outcome and produce incident payload.
5. Execute integration and persist support telemetry.

## Design Guardrails

- Prefer metadata records over code edits for business variance.
- Keep keys stable and human-auditable.
- Avoid ambiguous overlapping routing/mapping records.
- Preserve documentation URL links for change traceability.
- Separate schema (`force-app/config`) from sample records (`force-app/sample-config`).

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
- [Field Ownership Matrix](../process/field-ownership-matrix.md)
- [Use Case Register](../process/use-case-register.md)
- [Package Modularity Overview](package-modularity-overview.md)
