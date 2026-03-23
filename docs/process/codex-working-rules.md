# Codex Working Rules

## Objective

Build and maintain a metadata-driven, modular Apex REST integration framework that synchronizes Salesforce Cases with ServiceNow Incidents, supports multiple Salesforce orgs, and is suitable for enterprise healthcare governance.

## Primary repository prompt

Use the following instruction as the baseline prompt for work in this repository:

> Read this Salesforce DX project and treat it as an enterprise healthcare integration framework. All code must be metadata-driven, modular, packageable, and suitable for multi-org deployment. Do not hardcode business rules, routing, field mappings, or credentials. Generate secure Apex, Custom Metadata Types, tests, and documentation. Assume ServiceNow field mappings and process rules will evolve over time.

## Non-negotiable engineering rules

- Treat all integrations as subject to healthcare governance and audit requirements.
- Never hardcode credentials, secrets, endpoints, or environment-specific data.
- Prefer configuration through metadata over code-level branching.
- Avoid logging sensitive payloads or protected data.
- Separate orchestration from transport, mapping, and persistence layers.
- Produce tests and supporting documentation alongside implementation.
- Avoid destructive changes unless explicitly requested.
