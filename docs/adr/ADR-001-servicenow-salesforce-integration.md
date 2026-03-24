# ADR-001: Metadata-Driven Salesforce–ServiceNow Integration Architecture

- **Status:** Accepted
- **Date:** 2026-03-23
- **Last Reviewed:** 2026-03-24
- **Decision Owners:** Salesforce Platform Architecture, Integration Engineering, Support Operations, Security Architecture
- **Supersedes:** None
- **Superseded By:** None

## Context

UCLA Health requires a reusable, governable integration architecture that connects Salesforce Case-driven workflows to ServiceNow Incident management across multiple Salesforce orgs.

The implementation in this repository already includes:

- metadata-driven configuration types (`SN_Org_Config__mdt`, `SN_Request_Type__mdt`, `SN_Field_Mapping__mdt`, routing/assignment/template/toggle types),
- orchestration and support services in Apex (`SN_IntegrationOrchestrator`, `SN_ServiceNowClient`, `SN_TransactionLogService`, `SN_TransactionReplayService`, queueables),
- runtime observability objects (`Integration_Transaction__c`, `Integration_Error__c`, `SN_Integration_Error__c`, `ServiceNow_Incident_Link__c`, `SN_Integration_Run__c`),
- package separation for runtime/config/admin/sample artifacts.

Enterprise architecture and healthcare governance constraints include:

1. **Controlled change management:** routing and mapping behavior must be evolvable without frequent code releases.
2. **Security posture:** secrets and endpoint credentials must be managed via Salesforce platform credential frameworks.
3. **Traceability:** transactions must be observable and auditable with safe logging practices.
4. **Multi-org scalability:** one integration product should support multiple orgs with variable business behavior.
5. **Operational resilience:** retries, replay, and runbook-driven support must be available.

## Issue Statement

How should the integration be architected so that it remains reusable across orgs, secure for regulated operations, supportable by operations teams, and adaptable to evolving routing/mapping requirements without creating org-specific code forks?

## Decision

Adopt and continue enforcing a **metadata-driven, package-modular Salesforce integration architecture** where:

1. **Stable execution logic remains in Apex runtime services** (orchestration, validation, callouts, retry/replay, and transaction logging).
2. **Variable business behavior remains in deployable metadata** (org scope, request type behavior, routing, assignment, mapping, toggles, endpoint references).
3. **External connectivity uses Named Credential + External Credential** and never embeds secrets in Apex or custom objects.
4. **Observability is modeled as first-class runtime data** with safe summaries, correlation IDs, idempotency keys, error categories, and replay lifecycle states.
5. **Package boundaries remain explicit** so runtime, config schema, admin UX, and sample reference data can evolve with controlled dependencies.

## Alternatives Considered

### Alternative A — Hardcoded point-to-point Apex

Implement mapping/routing behavior directly in classes and triggers.

- **Pros:** Fastest initial implementation for one org.
- **Cons:** Poor multi-org scalability, frequent code deployments for business changes, higher regression risk, weak governance separation.
- **Decision:** Rejected.

### Alternative B — Middleware-first with thin Salesforce logic

Place routing/mapping orchestration in an external iPaaS layer and keep Salesforce thin.

- **Pros:** Centralized enterprise orchestration potential.
- **Cons:** Adds platform dependency and change path for use cases that this repo already supports in metadata; does not remove Salesforce-side governance responsibilities.
- **Decision:** Deferred (may complement future evolution).

### Alternative C — Flow-centric orchestration with minimal Apex

Use declarative automation as primary orchestration engine.

- **Pros:** Admin visibility for simple patterns.
- **Cons:** Lower control for transport errors, serialization, idempotency coordination, and testability for complex multi-org scenarios.
- **Decision:** Rejected as primary architecture (allowed for selective intake orchestration).

## Consequences

### Positive

- Reduces release friction for approved behavior changes by moving variance to metadata.
- Improves governance by separating policy/configuration from execution code.
- Increases reuse across orgs and onboarding consistency.
- Provides operational controls for retry/replay and safer incident triage.

### Negative / Trade-offs

- Strong metadata governance is required; weak metadata quality can cause runtime ambiguity.
- Documentation and cross-team process maturity become mandatory dependencies.
- Test strategy must continuously validate metadata permutations and failure classes.

## Assumptions

1. Salesforce remains the system of engagement for intake and context collection.
2. ServiceNow Incident APIs remain the downstream integration contract.
3. Security teams permit Named Credential / External Credential as enterprise-approved secret handling.
4. Operations teams use runbook-driven support on top of transaction/error objects.
5. Package promotion continues with current modular boundaries defined in `sfdx-project.json`.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Metadata drift across orgs | Routing/mapping inconsistency and incidents | Enforce lifecycle fields, effective dates, and review checklists in admin process docs |
| Credential misconfiguration | Outbound failures or auth lockouts | Pre-go-live config validation + support runbook triage for auth failures |
| Sensitive data exposure in logs | Compliance breach | Use safe summaries only, avoid raw payload persistence, periodic log review |
| Retry storms / replay misuse | Throughput degradation and duplicate updates | Replay eligibility controls, idempotency keys, failure taxonomy, operator runbook guardrails |
| Package boundary erosion | Coupling and release instability | Architecture review gate for metadata placement and dependency direction |

## Healthcare / Enterprise Governance Alignment

- **Least privilege:** permission-set-based operational access and credential isolation.
- **Auditability:** transaction and run records support post-incident traceability.
- **Change control:** metadata lifecycle fields and package modularity align with controlled promotion.
- **Data minimization:** safe summaries and redaction-oriented logging strategy reduce protected-data exposure.
- **Operational readiness:** documented runbooks for support, reprocessing, and feature toggles.

## Measurable Follow-up Actions

1. **ADR conformance checks:** during each release, verify all architecture documents still map to implemented package structure and classes.
2. **Observability KPI baseline:** track success rate, retry rate, replay backlog age, and mean time to triage by org/request type.
3. **Security validation cadence:** quarterly review of permission sets, credential references, and logging fields against security architecture.
4. **Metadata quality gate:** require request type onboarding checklist completion before activating new org/request type metadata.
5. **Decision refresh:** review this ADR every 6 months or on major scope change.

## Cross-links

- [ADR Index](README.md)
- [System Context](../architecture/system-context.md)
- [Logical Architecture](../architecture/logical-architecture.md)
- [Component Model](../architecture/component-model.md)
- [Metadata Architecture](../architecture/metadata-architecture.md)
- [Security Architecture](../architecture/security-architecture.md)
- [Observability Architecture](../architecture/observability-architecture.md)
- [Deployment Architecture](../architecture/deployment-architecture.md)
- [Package Modularity Overview](../architecture/package-modularity-overview.md)
- [Integration Support Runbook](../runbooks/integration-support-runbook.md)
- [Reprocessing Runbook](../runbooks/reprocessing-runbook.md)
- [Feature Toggle Runbook](../runbooks/feature-toggle-runbook.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
- [Use Case Register](../process/use-case-register.md)
