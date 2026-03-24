# Deployment Architecture

## Purpose
Define package topology, promotion sequence, and onboarding checkpoints across environments.

## Package Topology (from `sfdx-project.json`)

1. `SN_Integration_Config_Base` → `force-app/config`
2. `SN_Integration_Core_Runtime` → `force-app/core` (depends on config)
3. `SN_Integration_Admin` → `force-app/admin` (depends on config + core)
4. `SN_Integration_Sample_Config` → `force-app/sample-config` (depends on config)

## Deployment Sequence

1. Deploy `config` package.
2. Deploy `core` runtime package.
3. Configure/validate Named Credential and endpoint records.
4. Deploy `admin` package for operator/admin personas.
5. Deploy sample config only as onboarding scaffold (typically non-prod).
6. Activate org/request metadata through controlled change management.

## Environment Progression Model

- **Dev/Sandbox:** rapid metadata iteration, unit and integration validation.
- **UAT/Pre-prod:** end-to-end scenario validation and runbook rehearsal.
- **Production:** controlled activation, monitored rollout, rollback and replay readiness.

## Promotion Gates

- Metadata completeness checks (org/request/routing/mapping/toggles).
- Security checks (credential and permissions posture).
- Observability checks (telemetry fields available and reportable).
- Support readiness checks (runbook ownership and escalation paths).

## Cross-links

- [Package Modularity Overview](package-modularity-overview.md)
- [CI/CD Quality Gates](../release/ci-cd-quality-gates.md)
- [New Org Onboarding Flow](../process/new-org-onboarding.md)
- [Admin Configuration Guide](../admin/configuring-salesforce-servicenow-integration.md)
