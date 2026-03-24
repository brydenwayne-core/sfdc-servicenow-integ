# ADR-001: Metadata-Driven Salesforce–ServiceNow Integration Architecture

- **Status:** Accepted
- **Date:** 2026-03-23
- **Last Reviewed:** 2026-03-24
- **Decision Owners:** Salesforce Platform Architecture, Integration Engineering, Security Architecture, Support Operations
- **Decision Category:** Integration Architecture / Governance
- **Supersedes:** None
- **Superseded By:** None

## Context

UCLA Health needs a reusable integration package that syncs Salesforce Cases with ServiceNow Incidents across multiple orgs without per-org code forks. The implemented solution in this repository already includes:

- metadata-driven policy and routing in `force-app/config/main/default/objects/*__mdt/`,
- runtime orchestration and transport services in `force-app/core/main/default/classes/`,
- runtime observability objects in `force-app/core/main/default/objects/`,
- package modularity in `sfdx-project.json` (`config`, `core`, `admin`, `sample-config`).

Enterprise healthcare governance expectations require strict control for security, auditability, change management, and predictable support operations.

## Issue Statement

How do we standardize a single architecture that is secure, auditable, supportable, and reusable across orgs while allowing request-specific behavior to evolve through governed metadata rather than repeated Apex code changes?

## Decision Drivers

1. Minimize code release frequency for routing/mapping behavior changes.
2. Enforce least-privilege credential handling and platform-native secret management.
3. Preserve operational traceability for incident triage and post-incident review.
4. Support multi-org variation without branching the codebase.
5. Ensure replay/retry controls are deterministic and runbook-operated.

## Decision

Adopt a **metadata-driven, package-modular architecture** with the following mandatory controls:

1. **Runtime logic in Apex services** (`SN_IntegrationOrchestrator`, client, validation, retry/replay, transaction logging).
2. **Variable behavior in custom metadata** (`SN_Org_Config__mdt`, `SN_Request_Type__mdt`, `SN_Field_Mapping__mdt`, routing/assignment/template/toggle metadata).
3. **Outbound auth through Named Credential + External Credential** only; no secret material in Apex or custom object fields.
4. **First-class observability records** with correlation IDs, idempotency keys, lifecycle state, and failure-classification fields.
5. **Explicit package boundaries** for config schema, runtime execution, admin UX, and optional sample data.

## Alternatives Considered

### Alternative A — Hardcoded point-to-point Apex

- **Description:** Keep mappings/routing largely in code and update by deployment.
- **Pros:** Fast initial delivery for single-org pilot.
- **Cons:** High long-term release friction, weak multi-org reuse, high regression risk.
- **Outcome:** Rejected.

### Alternative B — Middleware-first orchestration

- **Description:** Move most routing and transformation responsibilities to iPaaS/middleware.
- **Pros:** Centralized enterprise orchestration and cross-platform policy controls.
- **Cons:** Extra dependency and operational layer; duplicates metadata-driven controls already implemented in Salesforce.
- **Outcome:** Deferred (future coexistence option, not baseline architecture).

### Alternative C — Flow-first orchestration

- **Description:** Use Salesforce Flow as primary execution engine and minimize Apex.
- **Pros:** Strong admin visibility for simple use cases.
- **Cons:** Lower control for idempotency, transport error handling, and replay semantics at scale.
- **Outcome:** Rejected as primary pattern; declarative orchestration remains optional for constrained intake use cases.

## Consequences

### Positive

- Faster policy evolution through metadata-only changes under governance.
- Better separation of duties between engineering, security, and admin operations.
- Improved multi-org onboarding consistency.
- More reliable support outcomes with standardized failure taxonomy and replay control.

### Negative / Trade-offs

- Metadata quality becomes a critical runtime dependency.
- Documentation and governance cadence must be sustained to avoid drift.
- Test strategy must continuously cover metadata permutations and failure classes.

## Assumptions

1. Salesforce remains the system of engagement for Case intake.
2. ServiceNow Incident APIs remain stable and enterprise-approved.
3. Security approval for Named Credential / External Credential remains in force.
4. Support teams operate against documented runbooks and transaction telemetry.
5. Package boundaries in `sfdx-project.json` continue as the release baseline.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Metadata drift between orgs | Routing/mapping inconsistency and production defects | Enforce lifecycle/effective-date fields + onboarding checklists + promotion controls |
| Credential misconfiguration | Authentication outages and elevated incident volume | Pre-go-live validation, credential ownership model, runbook triage path |
| Sensitive data leakage in telemetry | Compliance exposure | Safe summaries only, no raw payload persistence, periodic audit of telemetry fields |
| Replay misuse / retry storms | Duplicate updates and resource exhaustion | Idempotency keys, replay eligibility gates, operator approval steps |
| Package boundary erosion | Coupling and release instability | Architecture review gate for dependency direction and metadata placement |

## Enterprise & Healthcare Governance Alignment

- **Least privilege:** permission-set-scoped access for support/admin personas.
- **Auditability:** transaction, error, and run records provide reconstruction trace.
- **Change control:** metadata lifecycle fields and package isolation support controlled promotion.
- **Data minimization:** safe summaries and redaction-aware logging controls.
- **Operational readiness:** documented support, reprocessing, and toggle runbooks.

## Measurable Follow-up Actions

| Action | Metric | Owner | Target Cadence |
| --- | --- | --- | --- |
| ADR conformance checkpoint | % of architecture docs mapped to actual package/components | Architecture Council | Every release |
| Observability baseline | Success rate, retry rate, replay backlog age, MTTT by org | Support Operations | Weekly |
| Security control review | Credential + permission-set drift count | Security Architecture | Quarterly |
| Metadata onboarding quality gate | % of org/request activations with completed checklist | Admin Operations | Every onboarding event |
| Decision freshness | ADR review completed on schedule | Decision Owners | Every 6 months |

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
- [Process Index](../process/README.md)
- [Case Intake to Incident Creation Flow](../process/case-intake-to-incident-creation.md)
- [Incident Update to Case Sync Flow](../process/incident-update-to-case-sync.md)
