# Documentation Taxonomy Standard

## Purpose
Define the enterprise documentation taxonomy and formatting standards for this Salesforce-ServiceNow integration repository.

## Audience
Enterprise architects, technical writers, developers, admins, support teams, and release managers.

## Scope
All Markdown documentation in the repository, with primary focus on the `docs/` hierarchy.

## Related Documents
- [Documentation Hub](../README.md)
- [Documentation Master Index](../indexes/README.md)
- [Documentation Audit](documentation-audit.md)

## Operational Notes
- This standard is mandatory for newly created or significantly updated Markdown files.
- Conflicts between documents must be resolved using canonical precedence rules in this standard.

## Revision Considerations
- Update taxonomy rules when new operational domains or governance requirements are introduced.
- Record major taxonomy changes in an ADR and link it in this document.

## Core Content

## 1. Enterprise Taxonomy

All documents must map to exactly one primary taxonomy class.

| Taxonomy Class | Directory | Primary Purpose |
| --- | --- | --- |
| ADRs | `docs/adr/` | Capture durable architecture decisions, alternatives, and consequences. |
| Architecture | `docs/architecture/` | Describe system design, boundaries, non-functional and compliance architecture. |
| Process | `docs/process/` | Define governance, operating models, and delivery workflows. |
| Admin | `docs/admin/` | Describe platform configuration, permissions, and operational administration. |
| Runbooks | `docs/runbooks/` | Provide execution playbooks for recurring operations and incident response. |
| Troubleshooting | `docs/troubleshooting/` | Offer symptom-based diagnostic and remediation workflows. |
| Onboarding | `docs/onboarding/` | Orient new teams to context, architecture, and responsibilities. |
| Release | `docs/release/` | Define release readiness, quality gates, and promotion controls. |
| Knowledge Articles | `docs/knowledge/` | Publish quick-reference support knowledge by platform domain. |
| Indexes | `docs/indexes/` | Maintain category and role-based navigation maps. |

### 1.1 Canonical Precedence

When content overlaps, rely on this precedence order:

1. ADRs (decision truth)
2. Architecture docs (design truth)
3. Process docs (governance truth)
4. Admin + Runbooks (execution truth)
5. Troubleshooting + Knowledge articles (rapid-reference summaries that must link back to canonical truth)

## 2. Directory Structure Standard

Required documentation structure:

```text
docs/
  adr/
  architecture/
  process/
  admin/
  runbooks/
  troubleshooting/
  onboarding/
  release/
  knowledge/
    salesforce/
    servicenow/
  indexes/
```

Directory rules:

- Every major directory must include a `README.md` index file.
- Place each document in one canonical directory; reference from others via links instead of duplication.
- Platform-specific knowledge articles must live under `docs/knowledge/salesforce/` or `docs/knowledge/servicenow/`.

## 3. File Naming Standard

### 3.1 General Naming

- Use lowercase kebab-case: `<topic>.md`.
- Keep names descriptive and stable over time.
- Avoid versioned names in filenames (for example `final-v2`); revisions belong in content history.

### 3.2 ADR Naming

- Use `ADR-<3-digit>-<short-title>.md`.
- Example: `ADR-002-observability-canonical-model.md`.
- ADR numbers are immutable and never reused.

### 3.3 Knowledge Article Naming

- Salesforce articles: `ka-sf-<3-digit>-<topic>.md`
- ServiceNow articles: `ka-sn-<3-digit>-<topic>.md`

## 4. Required Document Header Template

Every Markdown document must include these sections in order:

1. `# <Title>`
2. `## Purpose`
3. `## Audience`
4. `## Scope`
5. `## Related Documents`
6. `## Operational Notes`
7. `## Revision Considerations`
8. `## Core Content`

Header rules:

- Purpose must describe intent in one to three sentences.
- Audience must name primary roles (for example, architects, admins, L1 support).
- Scope must define boundaries and exclusions.
- Related Documents must contain relative links to canonical references.

## 5. Required Sections by Taxonomy Class

| Taxonomy Class | Required Core Sections |
| --- | --- |
| ADR | Context, Decision, Options Considered, Consequences, Status |
| Architecture | Context, Logical/Physical Design, NFRs, Security/Compliance, Open Risks |
| Process | Inputs, Workflow Steps, Roles and Responsibilities, Controls, Outputs |
| Admin | Preconditions, Configuration Steps, Validation, Rollback, Security Notes |
| Runbook | Trigger Conditions, Immediate Actions, Detailed Procedure, Escalation, Exit Criteria |
| Troubleshooting | Symptoms, Diagnostics, Root Cause Patterns, Resolution Steps, Escalation |
| Onboarding | Prerequisites, Orientation Steps, Key Systems, Role Checklist, First-Week Outcomes |
| Release | Entry Criteria, Quality Gates, Promotion Steps, Backout Plan, Sign-off Matrix |
| Knowledge Article | Summary, Applicable Scenarios, Steps, References, Last Verification Context |

## 6. Cross-Linking Conventions

- Use relative Markdown links for internal references.
- Use descriptive link text (not "click here").
- Every troubleshooting and knowledge article must link to one canonical runbook or architecture doc.
- Every runbook must link to at least one escalation or governance process document.
- Every index must be updated when documents are added, moved, or renamed.

## 7. Audience and Role Definitions

| Role | Responsibilities in Documentation |
| --- | --- |
| Enterprise Architect | Owns architecture and ADR quality, consistency, and decision traceability. |
| Integration Engineer | Maintains technical implementation accuracy and reference links to code/config. |
| Salesforce Administrator | Maintains admin guides and validates metadata procedure correctness. |
| Support Analyst (L1/L2) | Maintains troubleshooting and knowledge article effectiveness from incidents. |
| Release Manager | Maintains release controls, quality gates, and promotion evidence requirements. |
| Product/Program Governance | Reviews process docs for compliance and operating model alignment. |

## 8. Role-Specific Variants

Where role-specific variants are needed, use these suffix conventions:

- `-architect.md`
- `-admin.md`
- `-support.md`
- `-release.md`

Variant rules:

- Keep shared canonical content in one base doc.
- Variant docs only contain role-specific procedures or views.
- Variant docs must link back to the base document in `Related Documents`.

## 9. Quality and Lifecycle Controls

- Review cadence: quarterly for architecture/process, monthly for runbooks/troubleshooting.
- Each incident-triggered update must include troubleshooting or runbook improvement.
- Outdated documents should be retained with a deprecation notice and pointer to replacement.
- Broken links are release blockers for documentation-focused changes.
