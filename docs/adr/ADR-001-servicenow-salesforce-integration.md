# ADR-001: Metadata-Driven Salesforce Case to ServiceNow Incident Integration

## Purpose
Capture architecture decisions and their consequences for the Salesforce-ServiceNow integration.

## Audience
Enterprise architects, engineering leadership, governance reviewers

## Scope
Decision context, selected option, and expected impacts for architecture choices.

## Related Documents
- [Documentation Taxonomy Standard](../architecture/documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

- **Status:** Accepted
- **Date:** 2026-03-23
- **Decision Owners:** Salesforce platform architecture, integration engineering, support operations

## Context

UCLA Health needs an enterprise integration pattern that connects Salesforce Cases with ServiceNow Incidents while remaining reusable across multiple Salesforce orgs. The first implementation targets an Apex REST integration between a Salesforce org and a shared ServiceNow instance, but the architecture must support future expansion to additional Salesforce orgs without duplicating code or creating org-specific forks.

Several constraints shape this decision:

- Case intake, routing, and operational support processes are still evolving.
- Different Salesforce orgs may require different routing, field mappings, assignment groups, and validation behavior.
- New ServiceNow fields, request types, and downstream support teams are expected over time.
- Security and audit expectations require managed credentials, traceable integration behavior, and controlled access to configuration.
- Support teams need enough observability to diagnose failed transactions without exposing sensitive data.

A hardcoded integration would deliver an initial connection quickly, but it would also make every routing or mapping change dependent on Apex deployments. That creates unnecessary release friction, makes org onboarding slower, and increases regression risk as the number of supported orgs grows.

## Decision

We will implement the Salesforce Case to ServiceNow Incident integration as a **metadata-driven Apex REST framework** with these core characteristics:

1. **Apex owns reusable framework behavior** such as orchestration, validation execution, transformation, callout handling, retry coordination, and logging.
2. **Configuration lives in deployable metadata** instead of Apex code wherever business behavior is expected to vary by org, use case, environment, or future rollout stage.
3. **ServiceNow connectivity uses secure Salesforce platform mechanisms** such as Named Credentials and External Credentials rather than embedded secrets.
4. **Business flows are modeled around Cases as the Salesforce system of engagement** and Incidents as the downstream service-management record.
5. **The design must support phased maturity** from outbound incident creation to richer bidirectional synchronization, comments, attachments, and additional org onboarding.

## Architectural Expectations

### Runtime pattern

The integration runtime should follow this high-level flow:

1. A Salesforce Case is created or updated through standard UI, automation, or API.
2. Apex evaluates metadata to determine whether the Case is in scope for ServiceNow synchronization.
3. Routing and field-mapping metadata are applied to build the target payload.
4. A ServiceNow client service performs a REST callout using a Named Credential.
5. The response updates the Case and an integration transaction log.
6. Subsequent sync events use the same metadata-driven rules for status, comments, file transfer, and error handling.

### Configuration boundaries

The following categories must live in metadata rather than code whenever feasible:

- Salesforce org identity or tenant definition
- Case type or integration use case definitions
- ServiceNow assignment group and routing rules
- Field-level mapping and defaulting behavior
- Incident template selection
- Feature flags and activation states
- Environment-specific endpoint references
- Optional processing toggles for comments, files, or status sync

## Why configuration must live in metadata instead of code

Configuration must live in metadata because the most likely sources of change are business-owned, org-specific, and operational rather than algorithmic. Routing changes, assignment group updates, queue realignment, field mapping revisions, and staged rollout toggles should not require Apex rewrites for every adjustment.

Using metadata provides the following benefits:

- **Lower cost of change:** administrators and release teams can update deployable configuration without reopening core integration logic.
- **Multi-org scalability:** the same codebase can support multiple Salesforce orgs using different metadata records instead of branching logic.
- **Safer deployments:** business-rule changes stay isolated from framework code, reducing regression scope.
- **Auditability:** configuration can be versioned, reviewed, and promoted through environments in a controlled way.
- **Phased rollout support:** features can be enabled selectively for one org or use case before broader adoption.
- **Packageability:** metadata-driven behavior aligns with Salesforce deployment and packaging models.

Code should remain responsible only for stable technical capabilities that are unlikely to change with each business-process adjustment.

## Security Expectations

The integration must meet these security expectations:

- Use Named Credentials and External Credentials for authentication and endpoint management.
- Never store usernames, passwords, client secrets, tokens, or endpoint URLs directly in Apex.
- Restrict integration execution to dedicated service identities and least-privilege permission models.
- Limit who can modify metadata that affects routing, field mappings, or endpoint behavior.
- Redact or avoid sensitive payload content in logs, platform events, debug statements, and custom objects.
- Preserve traceability through correlation identifiers, transaction status, and auditable configuration changes.
- Ensure failure handling does not leak protected information through user-facing errors.

## Alternatives Considered

### Alternative 1: Hardcoded point-to-point Apex integration

Build a direct Apex trigger or service that maps Case fields to ServiceNow fields in code and sends a callout with org-specific branching.

**Why not chosen:**

- Every mapping or routing change would require code changes and deployment.
- Supporting additional Salesforce orgs would increase conditional logic and maintenance burden.
- It would be harder to delegate safe process evolution to administrators.
- Testing complexity would grow as org-specific branches accumulate.

### Alternative 2: Middleware-first integration with minimal Salesforce logic

Push most mapping and routing responsibilities into an external middleware platform while Salesforce sends a generic payload.

**Why not chosen right now:**

- It adds another critical platform dependency for changes that Salesforce metadata can own effectively.
- The current need is for a reusable Salesforce-native framework that can be deployed across orgs.
- Core Case behavior, eligibility rules, and user feedback still need to be modeled close to Salesforce data and automation.

This alternative may still complement the design later for enterprise orchestration, but it does not replace the need for a metadata-driven Salesforce application layer.

### Alternative 3: Flow-only configuration with minimal Apex

Use Flow for orchestration and field mapping, keeping Apex only for callouts.

**Why not chosen as the primary pattern:**

- Complex mapping, retries, and structured logging are better handled in cohesive service classes.
- Large-scale multi-org integration logic can become difficult to test and govern when split heavily across automation assets.
- Apex provides stronger control over serialization, error handling, and transport abstraction.

Flow can still be used for intake and invoking services where appropriate, but it should not replace the core framework pattern.

## Consequences

### Positive consequences

- The solution becomes reusable across multiple Salesforce orgs.
- Business-rule changes can be promoted through metadata rather than repeated code edits.
- The architecture supports phased rollout of new synchronization capabilities.
- Security posture improves by separating secrets and endpoint management from code.
- Support teams gain more reliable observability through standardized logging and correlation.

### Negative consequences

- The initial design requires more upfront documentation and metadata modeling than a simple point integration.
- Metadata design quality becomes critical; poor configuration structure could create runtime ambiguity.
- Administrators need governance around who can change routing and mapping metadata.
- The framework requires strong test coverage to validate metadata-driven behavior.

## Implementation Notes

The implementation should introduce source documents and packageable assets that support this ADR, including:

- project context and architecture documentation,
- a use case register,
- a field ownership matrix,
- an operational support runbook,
- Custom Metadata Types for routing and mappings,
- Apex service layers for orchestration and transport,
- and integration logging with retry-aware status tracking.

## Decision Outcome

Accepted. All subsequent integration design and implementation work should align to this ADR unless a later ADR explicitly supersedes it.
