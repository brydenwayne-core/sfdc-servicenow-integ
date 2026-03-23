# sfdc-servicenow-integ

This repository is configured as a Salesforce DX (SFDX) project.

## Project structure

- `force-app/`: default Salesforce metadata package directory with starter folders for Apex, LWC, flows, objects, static resources, tabs, and related metadata types.
- `config/project-scratch-def.json`: default scratch org definition.
- `manifest/package.xml`: sample metadata manifest for retrieve/deploy commands.
- `sfdx-project.json`: Salesforce DX project configuration.

## Common commands

```bash
sf org login web --alias devhub
sf org create scratch --definition-file config/project-scratch-def.json --alias sn-integ-scratch --set-default --duration-days 7
sf project deploy start --source-dir force-app
sf project retrieve start --manifest manifest/package.xml
```
