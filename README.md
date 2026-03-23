# sfdc-servicenow-integ

A Salesforce DX repository for building a metadata-driven, modular Apex REST integration framework that synchronizes Salesforce Cases with ServiceNow Incidents for enterprise healthcare use cases.

## Repository structure

```text
repo-root/
  force-app/
    main/
      default/
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

## Working principles

- Treat the repository as an enterprise healthcare integration framework.
- Keep business rules, field mappings, routing, and credentials out of code.
- Prefer metadata-driven configuration and modular packageable design.
- Avoid logging sensitive payloads.
- Keep orchestration separate from transport and transformation.
- Generate tests with every Apex implementation.
- Do not make destructive changes without explicit instruction.

## Existing Salesforce DX configuration

- `sfdx-project.json` defines `force-app` as the default package directory.
- `manifests/package.xml` provides a starter deployment manifest.
- `config/project-scratch-def.json` remains available for scratch org creation.

## Common commands

```bash
sf org login web --alias devhub
sf org create scratch --definition-file config/project-scratch-def.json --alias sn-integ-scratch --set-default --duration-days 7
sf project deploy start --source-dir force-app
sf project retrieve start --manifest manifests/package.xml
```

## Codex repository instruction

Use this as the baseline instruction for Codex in this repo:

> Read this Salesforce DX project and treat it as an enterprise healthcare integration framework. All code must be metadata-driven, modular, packageable, and suitable for multi-org deployment. Do not hardcode business rules, routing, field mappings, or credentials. Generate secure Apex, Custom Metadata Types, tests, and documentation. Assume ServiceNow field mappings and process rules will evolve over time.
