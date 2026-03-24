# KA-SN-005 Integration Escalation Guide

## Purpose
Define when and how ServiceNow-side teams should escalate integration incidents.

## Audience
ServiceNow support leads, incident managers, and cross-platform coordinators.

## Scope
Escalation triggers, required evidence, and owner routing for persistent integration issues.

## Source of Truth
- [Escalation Guidance by Issue Type](../../troubleshooting/escalation-guidance-by-issue-type.md)
- [Integration Support Runbook](../../runbooks/integration-support-runbook.md)
- [Role-Specific Runbooks](../../runbooks/role-specific/README.md)

## Escalation Triggers
- Repeated failures after validated remediation.
- Cross-system data mismatch affecting incident lifecycle.
- SLA risk or customer-impacting outage signals.

## Required Escalation Package
- Incident/ticket reference and severity.
- Correlation IDs and affected request types.
- Error code set and time window.
- Actions performed and replay outcomes.
- Current owner and requested next owner.

## Owner Routing
- Salesforce config/metadata defects → Salesforce admin team.
- ServiceNow platform/data policy conflicts → ServiceNow platform owner.
- Unclear ownership/systemic outage → joint bridge with incident manager.
