# CI/CD Quality Gates

## Purpose
Define release readiness checks and deployment quality controls.

## Audience
Release managers, DevOps engineers, QA leads

## Scope
Quality gates, validation commands, and release governance expectations.

## Related Documents
- [Documentation Taxonomy Standard](../architecture/documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

This repository includes repo-native CI/CD helpers for validating Salesforce DX package quality without hardcoding environment details.

## Goals

The quality gates are designed to verify:

- static analysis results for Apex and web assets
- Apex unit test execution with code coverage reporting
- metadata deployment validation using dry-run deployment checks
- package readiness checks for the package directories defined in `sfdx-project.json`

## Scripts

All automation lives under `scripts/ci/`.

| Script | Purpose | Required inputs |
| --- | --- | --- |
| `scripts/ci/static-analysis.sh` | Runs Salesforce Code Analyzer (`sf scanner run`) across package directories. | `sf`, Java |
| `scripts/ci/apex-tests.sh` | Runs Apex tests with coverage in a target org. | `SF_TARGET_ORG` |
| `scripts/ci/validate-metadata.sh` | Performs a deployment validation (`sf project deploy validate`) against a target org. | `SF_TARGET_ORG` |
| `scripts/ci/package-checks.sh` | Confirms package directory metadata can generate a manifest and optionally checks package versions in a Dev Hub. | optional `SF_DEVHUB_ALIAS` |
| `scripts/ci/run-all.sh` | Runs all quality gates in sequence. | depends on all of the above |

## Environment variables

These scripts are environment-agnostic and rely on aliases or variables supplied by the execution environment.

| Variable | Meaning |
| --- | --- |
| `SF_TARGET_ORG` | Scratch org, sandbox, or packaging org alias used for tests and validation. |
| `SF_DEVHUB_ALIAS` | Optional Dev Hub alias for package version checks. |
| `SF_WAIT_MINUTES` | Optional wait duration for long-running Salesforce operations. Defaults to `30`. |
| `SF_TEST_LEVEL` | Optional deployment test level. Defaults to `RunLocalTests`. |
| `REPORTS_DIR` | Optional report output location. Defaults to `reports/`. |

## Local usage

Install the prerequisites:

```bash
npm install --global @salesforce/cli
sf plugins install @salesforce/sfdx-scanner
```

Then run quality gates individually or together:

```bash
./scripts/ci/static-analysis.sh
SF_TARGET_ORG=qa ./scripts/ci/apex-tests.sh
SF_TARGET_ORG=qa SF_TEST_LEVEL=RunLocalTests ./scripts/ci/validate-metadata.sh
SF_DEVHUB_ALIAS=devhub ./scripts/ci/package-checks.sh
SF_TARGET_ORG=qa SF_DEVHUB_ALIAS=devhub ./scripts/ci/run-all.sh
```

## GitHub Actions example

The example workflow in `.github/workflows/quality-gates.yml` shows one way to run the same scripts in CI.

Suggested repository secrets:

- `SF_AUTH_URL`: SFDX auth URL for the validation org
- `SF_TARGET_ORG`: alias to assign after authentication
- `SF_DEVHUB_AUTH_URL`: SFDX auth URL for the Dev Hub used for package checks
- `SF_DEVHUB_ALIAS`: alias to assign to the Dev Hub session

If no target org credentials are supplied, the workflow still runs static analysis and package structure checks.

## Design notes

- Package directories are discovered directly from `sfdx-project.json`, so new packages automatically participate in the gates.
- Deployment validation uses `sf project deploy validate` instead of a live deploy, making the default path safe for pull requests.
- Package checks remain optional for Dev Hub-backed environments so the scripts can run in sandboxes, scratch org pipelines, or local developer machines.

## Workflow reliability issue and durable fix (2026-03-24)

### Root cause

Repeated pull request failures were caused by a single-job workflow architecture that always initialized the full Salesforce toolchain (`sf` CLI, scanner plugin, Java runtime, org authentication steps) even for documentation-only changes.

Because docs-only pull requests do not modify deployable Salesforce metadata, these runs provided no release-safety value but still exercised the most failure-prone integration points (plugin install, auth setup, org-dependent commands). That increased false negatives and obscured real code-quality signals.

### Durable fix

The workflow is now split into path-aware jobs:

1. `detect-changes` classifies the PR into docs, Salesforce metadata/code, and workflow changes.
2. `docs-quality-gates` runs only when a pull request is docs-only.
3. `salesforce-quality-gates` runs whenever changes are not docs-only (including workflow changes and all Salesforce-impacting changes).

Design behaviors:

- docs-only PRs skip Salesforce CLI installation and org operations entirely.
- Salesforce-impacting PRs preserve enterprise gates: static analysis, optional Apex tests, optional metadata validation, and package checks.
- `workflow_dispatch` always executes the Salesforce gate path to support explicit release validation.
- authentication steps now require both secret material and alias values to avoid partial login attempts.

### Verification steps

Use representative PR change sets and confirm job routing:

1. **Docs-only PR** (`docs/**`, `README.md` only)
   - Expected: `detect-changes` + `docs-quality-gates`
   - Expected skip: `salesforce-quality-gates`
2. **Salesforce metadata/code PR** (`force-app/**`, `scripts/ci/**`, `sfdx-project.json`, `manifest*`)
   - Expected: `detect-changes` + `salesforce-quality-gates`
   - Expected skip: `docs-quality-gates`
3. **Workflow-only PR** (`.github/workflows/**`)
   - Expected: `detect-changes` + `salesforce-quality-gates`
4. **Manual dispatch** (`workflow_dispatch`)
   - Expected: `salesforce-quality-gates` always runs regardless of file deltas.

For each case, review the `Change summary` step output (`Docs changed`, `Salesforce changed`, `Workflow changed`, `Docs only`) to validate classification and routing.
