# Documentation Taxonomy and File Standards

- **Version:** 1.0
- **Effective date:** 2026-03-24
- **Applies to:** all Markdown documentation in this repository
- **Primary goals:** consistency, role clarity, operational usability, and enterprise governance traceability

## 1) Enterprise Documentation Taxonomy

All docs must map to one primary taxonomy family.

## 1.1 Taxonomy families

1. **Architecture (`docs/architecture/`)**
   - Purpose: describe target-state design, system boundaries, non-functional concerns, and architecture analysis.
   - Audience: architects, senior developers, security reviewers, release leadership.
2. **ADRs (`docs/adr/`)**
   - Purpose: capture durable architecture decisions with context, options, and consequences.
   - Audience: architects, engineering leadership, compliance/governance stakeholders.
3. **Process (`docs/process/`)**
   - Purpose: define delivery governance, SDLC rules, ownership frameworks, and planning artifacts.
   - Audience: engineering teams, product/program leadership, governance roles.
4. **Admin (`docs/admin/`)**
   - Purpose: configure and maintain integration metadata, access, and operational controls.
   - Audience: Salesforce admins, platform operators, release managers.
5. **Runbooks (`docs/runbooks/`)**
   - Purpose: execute operational procedures during normal operations and incidents.
   - Audience: operators, support analysts, on-call engineers.
6. **Troubleshooting / Knowledge Articles (`docs/knowledge/`)**
   - Purpose: fast symptom-based triage and resolution guidance.
   - Audience: L1/L2 support, operators, incident responders.
7. **Design patterns (`docs/design/`)**
   - Purpose: reusable implementation patterns and reference approaches.
   - Audience: developers and solution designers.

## 1.2 Canonical precedence

When overlap exists, treat precedence in this order:
1. ADRs (decision truth)
2. Architecture docs (design truth)
3. Admin/Runbooks (operational truth)
4. Process docs (governance truth)
5. Knowledge articles (rapid execution shortcuts that must link to the canonical source)

## 2) Directory Structure Standard

Required structure (current + added):

```text
docs/
  adr/
  architecture/
  admin/
  runbooks/
  process/
  design/
  knowledge/                 # new: troubleshooting and KB articles
```

Rules:
- Every folder should contain an index file (`README.md`) listing docs, purpose, owner, and last review date.
- Cross-family docs should live in one canonical family and be linked from others; avoid duplicate copies.

## 3) File Naming Standard

## 3.1 General naming

- Use lowercase kebab-case file names: `<topic>.md`
- Avoid overloaded terms like “overview-final-v2”.
- Name should reflect task or domain, not meeting date.

Examples:
- `incident-escalation-matrix.md`
- `security-control-matrix.md`
- `org-onboarding-checklist.md`

## 3.2 ADR naming

- Format: `ADR-<3-digit>-<short-title>.md`
- Example: `ADR-002-observability-canonical-model.md`

## 3.3 Knowledge article naming

- Format: `ka-<domain>-<symptom-or-task>.md`
- Example: `ka-support-replay-failed-transactions.md`

## 4) Required Document Header (All Docs)

Each file must begin with a metadata block:

```markdown
# <Title>

- **Doc Type:** <Architecture | ADR | Process | Admin | Runbook | Knowledge | Design>
- **Purpose:** <one sentence>
- **Audience:** <primary roles>
- **Owner:** <team or role>
- **Status:** <Draft | Active | Deprecated | Retired>
- **Last Reviewed:** YYYY-MM-DD
- **Related Docs:** [link-1](...), [link-2](...)
```

## 5) Required Sections by Document Type

## 5.1 Architecture docs

Required sections:
1. Purpose and scope
2. System context and boundaries
3. Design decisions and rationale (link ADRs)
4. Data/interaction flows (text + diagram reference if available)
5. Security/compliance considerations
6. Operational implications
7. Open issues / future work

## 5.2 ADRs

Required sections:
1. Context
2. Decision drivers
3. Options considered
4. Decision
5. Consequences (positive/negative)
6. Status and supersession references

## 5.3 Process docs

Required sections:
1. Objective
2. Trigger/events for process usage
3. Roles and responsibilities (RACI-lite)
4. Step-by-step workflow
5. Artifacts/evidence produced
6. Metrics and review cadence

## 5.4 Admin docs

Required sections:
1. Purpose and prerequisites
2. Configuration model
3. Change procedure
4. Validation checks
5. Rollback/recovery notes
6. Audit and approval expectations

## 5.5 Runbooks

Required sections:
1. Trigger conditions
2. Preconditions and safety checks
3. Procedure steps
4. Validation of success
5. Escalation path and severity guidance
6. Post-action documentation requirements

## 5.6 Troubleshooting / Knowledge articles

Required sections:
1. Symptom
2. Likely causes
3. Triage steps (quick)
4. Resolution steps
5. When to escalate
6. Related canonical docs

## 5.7 Design pattern docs

Required sections:
1. Problem statement
2. Recommended pattern
3. Anti-patterns to avoid
4. Extension points
5. Test/validation guidance

## 6) Audience Definitions and Role-Specific Variants

## 6.1 Core role set

- **Architect**: design governance, decision quality, scalability, and compliance fit.
- **Developer**: implementation detail, interfaces, testability.
- **Admin**: metadata configuration and environment management.
- **Operator/Support**: monitoring, incident response, reprocessing.
- **Security/Compliance**: controls, data handling, audit evidence.
- **Release manager**: promotion readiness, rollback strategy, dependencies.

## 6.2 Role-specific variants

For high-impact docs, provide role lenses:
- `*-architect-view.md` (decision rationale focus)
- `*-operator-view.md` (procedure focus)
- `*-admin-view.md` (configuration focus)

Use variants only when one doc cannot stay readable for multiple roles; otherwise keep single source with clear role subsections.

## 7) Cross-Linking Conventions

- Every doc must include at least 2 related-document links.
- Use relative links for repo portability.
- Use a “Canonical source” note when summarizing another doc.
- Add a “Next read” section at the end of architecture and process docs.

## 8) Taxonomy Rules for Existing Project Categories

## 8.1 Architecture docs

- Keep system-level intent and analysis in `docs/architecture/`.
- Move or alias broad overview documents into architecture with canonical pointers.

## 8.2 ADRs

- Create ADRs for any decision that changes package boundaries, security posture, tenancy model, observability model, or data ownership.

## 8.3 Process docs

- Keep governance artifacts (ownership matrix, use-case register, working rules).
- Add review cadence and owners to each.

## 8.4 Admin docs

- Keep setup and change procedures for metadata and credentials.
- Add explicit rollback and verification sections.

## 8.5 Runbooks

- Keep operational procedures and response playbooks.
- Ensure each runbook includes severity/escalation and evidence capture.

## 8.6 Troubleshooting docs

- Place rapid triage KAs in `docs/knowledge/`.
- Keep them short, action-oriented, and linked to canonical runbooks.

## 9) Supportability and Operational Standards

All operational docs (admin + runbook + knowledge) must include:
- explicit pre-checks,
- objective success criteria,
- escalation triggers,
- post-action logging expectations,
- and links to source-of-truth artifacts.

## 10) Governance and Maintenance Model

## 10.1 Review cadence

- Architecture + ADR docs: quarterly minimum
- Runbooks + admin docs: monthly verification minimum
- Knowledge articles: after each incident pattern change

## 10.2 Status lifecycle

Use status values consistently:
- `Draft`
- `Active`
- `Deprecated`
- `Retired`

Deprecated docs must include replacement references and retirement timeline.

## 10.3 Ownership

Each doc must have a named owning role/team and a backup reviewer role.

## 11) Definition of Done for New/Updated Docs

A documentation change is complete only if:
1. It conforms to taxonomy and naming rules.
2. Required header and required sections are present.
3. Related docs are linked.
4. Audience and operational impact are clear.
5. Outdated overlapping docs are updated or marked deprecated.

## 12) Immediate Backlog to Apply This Standard

1. Add `README.md` index files in each `docs/*` subfolder.
2. Add header metadata blocks to all existing docs.
3. Create `docs/knowledge/` and seed top support KAs from existing runbooks.
4. Normalize runbook templates for reprocessing, feature toggles, observability, and CI/CD operations.
5. Reclassify or pointer-link `docs/project-context-requirements-architecture-overview.md` to avoid canonical ambiguity.
