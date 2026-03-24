# Codex Working Rules

## Purpose
Define repeatable governance and delivery processes for the integration program.

## Audience
Delivery managers, architects, developers, admins

## Scope
Process steps, ownership models, and control points for change delivery.

## Related Documents
- [Documentation Taxonomy Standard](../architecture/documentation-taxonomy-standard.md); [Documentation Master Index](../indexes/README.md)

## Operational Notes
- Treat this document as part of the enterprise documentation system defined on 2026-03-24.
- Escalate conflicting guidance to architecture owners before implementation changes.

## Revision Considerations
- Update links and examples whenever repository structure or package boundaries change.
- Record substantial directional changes via ADRs and cross-link from this document.

## Core Content

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
