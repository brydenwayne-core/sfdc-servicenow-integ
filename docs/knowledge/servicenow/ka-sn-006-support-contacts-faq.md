# KA-SN-006 FAQ for ServiceNow Support Contacts

## Purpose
Provide quick answers to common ServiceNow support coordination questions.

## Audience
ServiceNow support contacts, on-call responders, and incident coordinators.

## Scope
FAQ focused on routing dependencies, sync failures, and cross-team collaboration.

## Source of Truth
- [Integration Support Runbook](../../runbooks/integration-support-runbook.md)
- [Troubleshooting Decision Tree](../../troubleshooting/troubleshooting-decision-tree.md)
- [Incident Sync Failure Patterns](../../troubleshooting/incident-sync-failure-patterns.md)

## FAQ
### Why did Salesforce create no incident for a valid case?
Most often this is routing metadata mismatch, request type gating, or upstream transaction failure before create callout.

### What should I request from Salesforce support first?
Correlation ID, transaction status, error code, affected request type, and exact timestamp range.

### When should ServiceNow teams avoid manual incident recreation?
Avoid manual recreation when replay is possible; manual actions can break correlation and produce duplicate lifecycle events.

### Who leads communication during a cross-platform outage?
Incident manager or designated integration owner should coordinate shared updates and owner handoffs.

### How should we handle repeated intermittent failures?
Track recurring signatures, quantify frequency, and escalate as systemic reliability risk instead of isolated incidents.
