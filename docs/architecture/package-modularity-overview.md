# Package Modularity Overview

## Purpose
Describe package boundaries, dependency direction, and change-governance implications.

## Package Boundaries

- **`force-app/config`**: integration metadata schema and credential definitions.
- **`force-app/core`**: runtime orchestration logic and observability objects.
- **`force-app/admin`**: admin app, tabs, flexipages, layouts, permission sets.
- **`force-app/sample-config`**: reference metadata used for onboarding examples.

## Dependency Direction

- `config` is foundational.
- `core` depends on `config`.
- `admin` depends on `config` + `core`.
- `sample-config` depends on `config` and is optional for production runtime.

## Boundary Rationale

- Isolates enterprise-governed schema from runtime implementation changes.
- Supports independent evolution of support UX and permissions.
- Prevents sample data from contaminating production-grade packages.
- Improves release predictability and rollback planning.

## Governance Rules

1. No runtime dependency on sample-config artifacts.
2. No org-specific records in base config/runtime packages.
3. Any dependency direction change requires architecture review and ADR update.
4. Promotion evidence must include package impact statement.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Deployment Architecture](deployment-architecture.md)
- [Package Boundaries (detailed)](package-boundaries.md)
- [Metadata Architecture](metadata-architecture.md)
- [Use Case Register](../process/use-case-register.md)
