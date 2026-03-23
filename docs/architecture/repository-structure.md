# Repository Structure

This repository is organized to support a metadata-driven Salesforce-to-ServiceNow integration framework with clear separation between platform code, deployable metadata, architecture decisions, and operating documentation.

## Top-level layout

- `force-app/main/default/`: primary Salesforce metadata source for Apex, Custom Metadata Types, flows, permission sets, and other packageable components.
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
