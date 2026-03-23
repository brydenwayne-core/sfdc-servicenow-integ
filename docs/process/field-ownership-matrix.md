# Field Ownership Matrix

## Purpose

This matrix defines which platform is authoritative for major data domains involved in the Salesforce Case to ServiceNow Incident integration. It is intended to reduce ambiguity during implementation and future bidirectional synchronization design.

## Ownership Matrix

| Data Domain | Salesforce System of Record | ServiceNow System of Record | Notes |
| --- | --- | --- | --- |
| Salesforce Case Id | Yes | No | Native Salesforce identifier used for correlation and support lookup. |
| ServiceNow Incident Number / Sys Id | No | Yes | Must be stored back on the Salesforce Case after successful creation. |
| Requesting user context | Yes | No | Originates from Salesforce intake and should be transmitted to ServiceNow as context. |
| Case intake category and subcategory | Yes | No | Selected in Salesforce and mapped to ServiceNow categorization fields through metadata. |
| ServiceNow assignment group | No | Yes | Determined through integration routing rules, then owned operationally in ServiceNow after creation unless sync rules state otherwise. |
| Case owner queue | Yes | No | Salesforce ownership remains local unless future process explicitly couples it to incident routing. |
| Incident state | Shared | Shared | Requires explicit mapping policy and loop prevention controls. |
| Priority / severity | Shared | Shared | Mapping direction and conflict rules must be defined in metadata. |
| Customer-visible comments | Shared | Shared | Must respect visibility and replay-prevention rules. |
| Internal support notes | Conditional | Conditional | Requires policy decision before sync; not all note types should cross systems. |
| Attachments / files | Shared | Shared | Synchronization subject to size, policy, and content restrictions. |
| Integration transaction status | Yes | No | Operational logging should be maintained in Salesforce for this framework. |
| Endpoint credentials | No | No | Managed through secure platform credential services, not business data ownership. |

## Guidance

- When ownership is marked **Shared**, implementation must include metadata-driven direction rules and conflict handling.
- When ownership is split by lifecycle stage, the integration should document the handoff explicitly in mappings or runbooks.
- New fields should be added to this matrix before bidirectional synchronization logic is introduced.
