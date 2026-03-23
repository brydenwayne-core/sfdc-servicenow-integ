# sfdc-servicenow-integ

A Salesforce DX repository for building a metadata-driven, modular Apex REST integration framework that synchronizes Salesforce Cases with ServiceNow Incidents for enterprise healthcare use cases.

## Repository structure

```text
repo-root/
  force-app/
    core/
      main/
        default/          # reusable framework metadata and code
    admin/
      main/
        default/          # admin app, tabs, layouts, permissions, reports, dashboards
    sample-config/
      main/
        default/          # sample custom metadata records for example org setups
  docs/
    adr/
    architecture/
    runbooks/
    process/
  scripts/
  manifests/
  .codex/
    config.toml
  README.md
```

## Packaging model

- **Core framework package**: Apex orchestration, custom objects, custom metadata type definitions, credentials, and reusable observability model.
- **Admin package**: internal operational console metadata such as tabs, layouts, permission sets, reports, dashboards, and the admin application shell.
- **Sample config package**: non-production example custom metadata records demonstrating how different orgs can configure request types, routing, endpoint keys, and org definitions.

This split keeps reusable framework assets isolated from org-specific samples while still allowing an operational/admin layer to be installed where needed.

## Centralized incident visibility design

The repository now includes a normalized `ServiceNow_Incident_Link__c` model intended to support future centralized reporting patterns across multiple Salesforce orgs.

Normalization principles:

- store the Salesforce org code and business unit alongside each link
- snapshot the Salesforce source object API name and source record label rather than relying on org-specific field layouts
- preserve the ServiceNow incident ID and incident number independently
- link each normalized record back to the originating `Integration_Transaction__c` for observability and retry analysis

These hooks support future aggregation in an admin org without assuming every source org uses the same exact field configuration.

## Working principles

- Treat the repository as an enterprise healthcare integration framework.
- Keep business rules, field mappings, routing, and credentials out of code.
- Prefer metadata-driven configuration and modular packageable design.
- Avoid logging sensitive payloads.
- Keep orchestration separate from transport and transformation.
- Generate tests with every Apex implementation.
- Do not make destructive changes without explicit instruction.

## Existing Salesforce DX configuration

- `sfdx-project.json` defines three package directories: `force-app/core`, `force-app/admin`, and `force-app/sample-config`.
- `manifests/package.xml` and `manifest/package.xml` provide starter deployment manifests.
- `config/project-scratch-def.json` remains available for scratch org creation.

## Common commands

```bash
sf org login web --alias devhub
sf org create scratch --definition-file config/project-scratch-def.json --alias sn-integ-scratch --set-default --duration-days 7
sf project deploy start --source-dir force-app/core
sf project deploy start --source-dir force-app/admin
sf project deploy start --source-dir force-app/sample-config
sf project retrieve start --manifest manifests/package.xml
```

## CI/CD quality gates

Repo-native CI/CD helpers now live in `scripts/ci/` with a matching GitHub Actions example in `.github/workflows/quality-gates.yml`. The gates cover static analysis, Apex tests, metadata validation, and package readiness checks without hardcoding environment-specific org names. See `docs/runbooks/ci-cd-quality-gates.md` for setup and usage details.

## Codex repository instruction

Use this as the baseline instruction for Codex in this repo:

> Read this Salesforce DX project and treat it as an enterprise healthcare integration framework. All code must be metadata-driven, modular, packageable, and suitable for multi-org deployment. Do not hardcode business rules, routing, field mappings, or credentials. Generate secure Apex, Custom Metadata Types, tests, and documentation. Assume ServiceNow field mappings and process rules will evolve over time.
