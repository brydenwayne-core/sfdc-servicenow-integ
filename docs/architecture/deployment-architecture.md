# Deployment Architecture

## Purpose
Describe package installation order, environment promotion, and org onboarding flow.

## Package Topology

Defined in `sfdx-project.json` as four package directories:

1. `SN_Integration_Config_Base` (`force-app/config`)
2. `SN_Integration_Core_Runtime` (`force-app/core`) depends on config base
3. `SN_Integration_Admin` (`force-app/admin`) depends on config + core
4. `SN_Integration_Sample_Config` (`force-app/sample-config`) depends on config base

## Recommended Deployment Sequence

1. Deploy/install config base.
2. Deploy/install runtime package.
3. Configure and validate credentials/endpoints.
4. Deploy/install admin package for support personas.
5. Deploy sample config only to non-production or as onboarding scaffold.
6. Promote approved org-specific metadata records.

## Environment Model

- **Lower environments:** validate request types, routing, and mappings with sample scaffolds.
- **Pre-production:** run config validation and integration test scenarios.
- **Production:** controlled metadata activation with rollback/replay plan.

## Onboarding Control Points

- Endpoint and org config existence/active state.
- Request type completeness (mapping, template, routing, assignment).
- Feature toggle posture and kill-switch defaults.
- Support readiness (dashboards, runbooks, ownership).

## Cross-links

- [ADR-001](../adr/ADR-001-servicenow-salesforce-integration.md)
- [Package Modularity Overview](package-modularity-overview.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
- [CI/CD Quality Gates](../release/ci-cd-quality-gates.md)
- [Onboarding Architecture Overview](../onboarding/project-context-requirements-architecture-overview.md)
