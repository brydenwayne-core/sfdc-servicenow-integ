# Use Case Register

## Purpose
Define repeatable governance and delivery processes for the integration program.

## Audience
Delivery managers, architects, developers, admins

## Scope
Process steps, ownership models, and control points for change delivery.

## Related Documents
- [Documentation Taxonomy Standard](../architecture/documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

## Overview

This register defines the current and planned business use cases for the Salesforce Case to ServiceNow Incident integration. It is intended to drive architecture, metadata design, delivery sequencing, and test coverage.

## Use Cases

| ID | Use Case | Summary | Trigger | Primary Salesforce Record | Primary ServiceNow Record | Configuration Needs | Initial Phase |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UC-001 | Incident creation | Create a ServiceNow Incident from an eligible Salesforce Case. | New Case creation or explicit submission action. | Case | Incident | Eligibility rules, field mappings, routing, templates, endpoint references. | MVP |
| UC-002 | Status synchronization | Synchronize key status values between Salesforce Case and ServiceNow Incident. | Status change in either platform, depending on rollout phase. | Case | Incident | Status mapping matrix, conflict rules, activation toggles, sync direction controls. | Phase 2 |
| UC-003 | Comment synchronization | Exchange customer-visible or support comments between Case and Incident. | New comment or work note event. | Case / Feed or comment object | Incident work notes / comments | Comment eligibility rules, field mapping, visibility rules, author handling, feature flags. | Phase 2 |
| UC-004 | File synchronization | Send or receive relevant files associated with a Case and Incident. | Attachment added or selected for transmission. | Case / ContentDocument | Incident attachment | File type controls, size thresholds, retention rules, direction toggles, error handling. | Phase 2 |
| UC-005 | Org-specific routing | Route Cases to different ServiceNow assignment groups, templates, or queues based on source org and business rules. | Case create/update with in-scope attributes. | Case | Incident | Org definitions, routing rules, assignment mappings, request type metadata. | MVP |
| UC-006 | Additional Salesforce org onboarding | Extend the framework to new Salesforce orgs with minimal code change. | New org joins the shared integration model. | Case | Incident | Tenant metadata, org activation records, routing variants, permission model, deployment checklist. | Phase 3 |

## Detailed Use Case Notes

### UC-001 Incident creation

**Goal:** ensure an in-scope Salesforce Case creates a corresponding ServiceNow Incident using metadata-driven field translation and secure REST callouts.

**Key requirements:**

- Prevent duplicate incident creation when a Case is retried.
- Store and maintain the ServiceNow incident identifier on the Case.
- Capture request, response, correlation, and error status in operational logs.
- Support default values and org-specific routing behavior through metadata.

### UC-002 Status synchronization

**Goal:** keep meaningful lifecycle states aligned between Salesforce and ServiceNow without introducing update loops.

**Key requirements:**

- Maintain a configurable status mapping table.
- Support directional control for phased rollout.
- Record source-of-truth and conflict-handling expectations.
- Exclude statuses that should remain platform-local.

### UC-003 Comment synchronization

**Goal:** share relevant commentary between users and support teams while preserving visibility rules and auditability.

**Key requirements:**

- Distinguish internal notes from customer-visible comments.
- Normalize authorship and timestamps when crossing systems.
- Prevent duplicate replay of previously synchronized comments.
- Allow comment sync to be enabled by org or use case.

### UC-004 File synchronization

**Goal:** move required supporting files between Case and Incident records in a controlled and compliant manner.

**Key requirements:**

- Restrict synchronized files based on type, size, and policy.
- Preserve traceability to the originating Case or Incident.
- Handle partial failures separately from core incident creation.
- Avoid transferring files that violate security or retention expectations.

### UC-005 Org-specific routing

**Goal:** let each Salesforce org apply its own routing logic without diverging from the shared integration framework.

**Key requirements:**

- Support org-specific assignment groups and incident templates.
- Allow request type, category, severity, or business-unit-based routing.
- Keep routing behavior in deployable metadata rather than Apex branching.
- Support deactivation or phased rollout per org.

### UC-006 Additional Salesforce org onboarding

**Goal:** make future org expansion primarily a configuration and enablement exercise instead of a redevelopment project.

**Key requirements:**

- Reuse the same Apex framework and metadata model.
- Allow new orgs to define their own routing, mappings, and feature toggles.
- Establish a repeatable onboarding checklist and support model.
- Keep existing org behavior stable while adding new tenants.

## Dependencies Across Use Cases

- Incident creation is the foundational use case that all other use cases build upon.
- Status, comments, and file synchronization depend on durable cross-system identifiers.
- Org-specific routing shapes both incident creation and all future synchronization behavior.
- Expansion to additional orgs depends on a clean metadata model, permission design, and runbook maturity.

## Delivery Guidance

Use cases should be implemented in the following order:

1. Incident creation
2. Org-specific routing
3. Status synchronization
4. Comment synchronization
5. File synchronization
6. Additional Salesforce org onboarding at scale
