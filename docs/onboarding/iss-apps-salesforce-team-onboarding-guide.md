# ISS Apps Salesforce Team Onboarding Guide

## Purpose
Provide a practical onboarding path for new team members supporting and evolving the Salesforce ↔ ServiceNow integration framework.

## Audience
- Salesforce administrators
- Salesforce developers
- ISS support analysts
- Architects and technical leads
- Program and operations stakeholders

## Scope
Business context, architecture orientation, configuration model, operational responsibilities, and role-specific starting points for this repository.

## Related Documents
- [Documentation Hub](../README.md)
- [Project Context + Requirements + Architecture Overview](project-context-requirements-architecture-overview.md)
- [Documentation Master Index](../indexes/README.md)

## 1) Business Context

The ISS Apps Salesforce team owns an integration capability that connects Salesforce Cases with ServiceNow incidents. The team’s mission is to provide a stable, auditable, and scalable support intake and incident lifecycle pattern that can be reused across multiple Salesforce orgs.

### Why this project exists
- Standardize issue intake quality from Salesforce into ServiceNow.
- Reduce manual triage and routing effort using metadata-driven rules.
- Improve support visibility through transaction-level logging and runbooks.
- Enable multi-org expansion without cloning business logic per org.

### Business outcomes expected from the team
- Faster, more accurate incident creation and assignment.
- Better auditability of support transactions and failures.
- Lower long-term change cost through admin-managed configuration.
- Safer rollout of process changes across environments and orgs.

## 2) Architecture Overview (What New Team Members Should Know First)

### End-to-end flow
1. A Salesforce user submits an intake (typically Case/Flow-driven).
2. Metadata determines request type behavior, routing, and mapping.
3. Apex orchestration validates and transforms payloads.
4. ServiceNow callouts occur via secure credentials.
5. Response identifiers/status are written back to Salesforce.
6. Operational logs capture correlation, status, and error context.

### Architectural layers
- **Intake/UI layer**: captures structured issue data.
- **Business/routing layer**: determines behavior by metadata.
- **Mapping/translation layer**: converts Salesforce data to ServiceNow payloads.
- **Integration layer**: outbound/inbound interaction services.
- **Observability layer**: logs, monitoring, and reprocessing controls.

### Key architecture characteristics
- Metadata-driven variation rather than org-specific code forks.
- Security-first integration (credential abstraction, least privilege).
- Operational resilience (async patterns, retry/reprocess readiness).
- Design for phased maturity (MVP outbound first, broader sync later).

## 3) Key Configuration Concepts

The framework relies on deployable metadata to make behavior adaptable without constant Apex changes.

### Core configuration domains
- **Org configuration**: org identity, enablement, and environment behavior.
- **Request/ticket types**: intake type definitions and conditional behavior.
- **Routing rules**: queue/group assignment logic and targeting.
- **Field mappings**: source-to-target transformation definitions.
- **Incident templates**: payload defaults and controlled value sets.
- **Feature toggles**: phased enablement and safe release controls.
- **Endpoint references**: named credential/external credential usage.

### Configuration lifecycle expectations
- Promote through environment pipelines, not manual production-only edits.
- Pair config changes with validation and rollback plans.
- Keep mapping/routing intent documented in process and runbook docs.

## 4) Operational Responsibilities by Role

### Administrators
- Maintain config metadata quality and governance.
- Manage feature toggles, request type activation, and routing updates.
- Coordinate release readiness and post-deploy validation.
- Ensure access model and operational permissions remain compliant.

### Developers
- Build/maintain Apex orchestration and integration services.
- Keep logic cohesive and testable with clear layer boundaries.
- Implement diagnostics and safeguards for retry/recovery behavior.
- Partner with admins to keep business behavior metadata-driven.

### Support analysts
- Monitor transaction outcomes and investigate failed sync attempts.
- Classify issues using troubleshooting categories and decision trees.
- Execute first-line triage and escalate with complete evidence.
- Track incident-to-case synchronization outcomes and communication.

### Architects / application owners
- Maintain architecture guardrails and decision records.
- Review changes for scalability, security, and multi-org fit.
- Govern document quality, taxonomy alignment, and canonical ownership.

## 5) Document Map (Where Information Lives)

### Start here
- `docs/README.md` — documentation hub.
- `docs/indexes/README.md` — master navigation entry.

### Core orientation
- `docs/onboarding/project-context-requirements-architecture-overview.md`
- `docs/architecture/README.md`
- `docs/architecture/system-context.md`
- `docs/architecture/logical-architecture.md`

### Configuration and operations
- `docs/admin/README.md`
- `docs/process/README.md`
- `docs/runbooks/README.md`
- `docs/troubleshooting/README.md`

### Governance and evolution
- `docs/adr/README.md`
- `docs/release/README.md`
- `docs/knowledge/README.md`

## 6) Where to Begin by Persona (First 2 Weeks)

### If you are a Salesforce admin
1. Read the admin handbook and integration configuration guide.
2. Review field ownership, routing, and metadata-driven process docs.
3. Walk through feature-toggle and release quality gate runbooks.
4. Shadow one deployment/reconfiguration cycle in a lower environment.

### If you are a Salesforce developer
1. Read architecture core docs (system, component, metadata, security).
2. Review process docs for intake-to-incident and update synchronization.
3. Study runbooks for observability, reprocessing, and failure handling.
4. Implement a small non-breaking enhancement with tests and documentation.

### If you are an ISS support analyst
1. Read support runbook + role-specific support analyst runbook.
2. Learn failure categories, escalation guidance, and decision tree flow.
3. Review ServiceNow/Salesforce knowledge articles for common triage cases.
4. Practice a simulated incident triage and escalation handoff.

## 7) First-Month Onboarding Checklist

- Gain access to required Salesforce environments and support tooling.
- Confirm understanding of request types, routing, and mapping ownership.
- Complete one supervised operational activity relevant to your role.
- Complete one documentation update to reinforce repository familiarity.
- Review active ADRs and current architecture gaps/backlog themes.

## 8) Operating Cadence for New Team Members

- **Weekly**: review new incidents, top failure modes, and recent deploy changes.
- **Bi-weekly**: validate documentation freshness for touched areas.
- **Monthly**: review architecture roadmap items and scale-readiness concerns.

## 9) Escalation and Communication Principles

- Escalate early when failures indicate systemic mapping/routing defects.
- Include correlation IDs, impacted orgs, timestamps, and error signatures.
- Distinguish configuration defects from platform/service interruptions.
- Capture post-incident learnings in runbooks or knowledge articles.
