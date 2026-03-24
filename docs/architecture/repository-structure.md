# Repository Structure

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

This repository is organized to support a metadata-driven Salesforce-to-ServiceNow integration framework with clear separation between platform code, deployable metadata, architecture decisions, and operating documentation.

## Top-level layout

- `force-app/core/main/default/`: runtime Apex, async jobs, runtime objects, and integration observability assets.
- `force-app/config/main/default/`: configuration schema metadata and secure connection assets used by the runtime.
- `force-app/admin/main/default/`: operational/admin app metadata such as tabs, layouts, and permission sets.
- `force-app/sample-config/main/default/`: sample custom metadata records used as rollout examples, not production truth.
- `docs/adr/`: architecture decision records for long-lived technical decisions.
- `docs/architecture/`: system design documentation, integration patterns, and module boundaries.
- `docs/runbooks/`: operational procedures for deployment, incident handling, support, and recovery.
- `docs/process/`: delivery processes, governance guidance, and change management artifacts.
- `scripts/`: utility scripts for validation, packaging, metadata generation, and CI/CD support.
- `manifests/`: Salesforce package and deployment manifests.
- `.codex/config.toml`: repository-scoped instructions for Codex.

## Design intent

The structure is optimized for enterprise healthcare governance:

1. Keep platform assets packageable and ready for multi-org deployment.
2. Separate architecture rationale from operational runbooks.
3. Capture repo-specific AI coding rules close to the codebase.
4. Preserve room for future metadata-driven modules and automation scripts.
5. Support clearer unlocked-package layering between runtime, config schema, admin UX, and sample org data.
