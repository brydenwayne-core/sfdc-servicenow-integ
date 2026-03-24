# Salesforce Intake Pattern

## Purpose
Describe system design, constraints, and non-functional architecture guidance.

## Audience
Architects, senior engineers, security reviewers, release leaders

## Scope
Target architecture, logical boundaries, and design quality concerns.

## Related Documents
- [Documentation Taxonomy Standard](documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

## Goal

Deliver a service-catalog-style intake experience on top of `Case` while keeping request behavior, routing, validation, and downstream orchestration in deployable metadata instead of hardcoded page logic.

## Recommended UX Pattern

1. **Primary entry point:** a Lightning record page or utility-bar action that launches a Screen Flow.
2. **Record model:** the Flow creates or updates a `Case` as the durable intake record.
3. **Guided experience:** the Flow presents request-type-specific screens, help text, and conditional fields.
4. **Submission action:** the Flow calls invocable Apex or an action that ultimately reaches `SN_CaseIntakeController.submitCaseForIncident`.
5. **Async handoff:** incident submission runs through `SN_IncidentSyncQueueable` so the user receives a fast acknowledgment while integration processing continues in the background.

## Metadata-Driven Design

### Use `SN_Request_Type__mdt` as the admin-owned request catalog

Each request type record should define:

- request type key,
- source object (`Case`),
- operation mode,
- routing key,
- incident template key,
- active/inactive state,
- org scope.

This makes request types the equivalent of catalog items without hardcoding separate flows per request.

### Keep business rules in metadata or Apex services, not in screen logic

The Flow should only gather data and call reusable services. Core decisioning should stay in:

- `SN_ConfigService` for request type and org resolution,
- `SN_CaseIntakeSupport` for request-type discovery,
- `SN_CaseIntakeController` for submission-time validation,
- `SN_FieldMappingService` for field translation,
- `SN_RoutingService` for assignment behavior,
- `SN_IntegrationOrchestrator` for transport orchestration.

## Validation Hook Pattern

Use a two-stage validation model:

1. **Flow-time guidance:** screen-level requiredness and conditional visibility for usability.
2. **Server-side enforcement:** `SN_CaseIntakeController.validateCaseForSubmission` as the final validation gate before enqueueing integration.

That split keeps the UX friendly while ensuring API, automation, and future channels all obey the same rules.

## Future Flow Build Pattern

For each new request type:

1. Add or update `SN_Request_Type__mdt`.
2. Add or update field mappings in `SN_Field_Mapping__mdt`.
3. Add routing metadata if assignment behavior changes.
4. Expose the new request type automatically through `SN_CaseIntakeSupport.getCaseIntakeRequestTypes`.
5. Reuse the same submission action and async orchestration path.

## Minimal Hardcoded UI Logic Principles

- Use Flow for sequencing and user help, not business rules.
- Use metadata keys instead of branching by label text.
- Prefer one reusable Flow with dynamic sections over many cloned Flows.
- Keep downstream submission asynchronous.
- Make request type availability and behavior org-aware through metadata.
