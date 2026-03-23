# Project Context

## Purpose

This project establishes a metadata-driven Salesforce integration framework that synchronizes Salesforce Cases with ServiceNow Incidents. The framework is intended to solve an immediate integration need while creating a repeatable architectural pattern for future Salesforce org onboarding.

## Business Goal

Support teams need a consistent way to route support issues from Salesforce into ServiceNow without relying on manual re-entry or brittle org-specific customizations. The project should improve issue intake quality, reduce handoff friction, and create a scalable operating model for multiple Salesforce orgs.

## Scope

### In scope

- Outbound integration from Salesforce Cases to ServiceNow Incidents
- Metadata-driven routing, field mapping, and incident templating
- Secure callouts using Salesforce-supported credential management
- Transaction logging and support visibility
- Support for org-specific behavior without forking the codebase
- Expansion path for status sync, comments, files, and additional orgs

### Out of scope for the initial phase

- Replacing ServiceNow as the system of record for incident management
- Full middleware-led transformation as the primary architecture
- One-off per-org custom implementations outside the shared framework pattern
- Storing secrets or endpoints directly in code

## Stakeholders

- Salesforce platform architecture
- Salesforce development team
- ServiceNow platform team
- Support operations and help desk teams
- Security and compliance reviewers
- Release and environment management teams

## Architectural Drivers

- Multi-org scalability
- Metadata over hardcoded business rules
- Secure enterprise integration patterns
- Operational observability and recoverability
- Controlled change management through deployable configuration
- Ability to expand incrementally without redesigning the foundation

## Success Criteria

- A Case can be routed to ServiceNow based on metadata rather than code branching.
- The framework can support different routing behavior for different Salesforce orgs.
- Integration failures can be diagnosed using structured logs and correlation identifiers.
- Adding a new org or request type requires configuration-first changes wherever possible.
- The design supports future bidirectional sync features without major rework.
