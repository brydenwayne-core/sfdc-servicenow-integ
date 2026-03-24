# Package Modularity Overview

## Purpose
Provide an architecture-level view of package boundaries and dependency intent.

## Boundary Principles

- Runtime logic and runtime objects are isolated in `force-app/core`.
- Metadata schema and secure endpoint definitions are isolated in `force-app/config`.
- Admin UX and permissioning assets are isolated in `force-app/admin`.
- Example reference records are isolated in `force-app/sample-config`.

## Dependency Direction

- `config` is foundational.
- `core` depends on `config`.
- `admin` depends on `config` + `core`.
- `sample-config` depends on `config` and remains optional for production.

## Why This Matters

- Supports reusable productization across many orgs.
- Reduces coupling between runtime execution and support UX evolution.
- Enables controlled governance for schema vs implementation-specific records.
- Improves release predictability through explicit install order.

## Anti-Patterns to Avoid

- Placing org-specific sample records in runtime/config packages.
- Making runtime behavior depend on admin-only artifacts.
- Introducing package cycles through metadata placement drift.

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Package Boundaries (detailed)](package-boundaries.md)
- [Deployment Architecture](deployment-architecture.md)
- [Repository Structure](repository-structure.md)
