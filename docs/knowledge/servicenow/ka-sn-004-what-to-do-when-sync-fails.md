# KA-SN-004 What to Do When Sync Fails

## Purpose
Provide a fast response checklist for ServiceNow-facing teams when integration sync failures occur.

## Audience
ServiceNow support analysts, integration operators, and on-call responders.

## Scope
Immediate triage, impact assessment, and coordinated remediation for failed sync events.

## Source of Truth
- [Incident Sync Failure Patterns](../../troubleshooting/incident-sync-failure-patterns.md)
- [Failure Classification and Triage](../../process/failure-classification-and-triage.md)
- [Reprocessing Runbook](../../runbooks/reprocessing-runbook.md)

## Immediate Response
1. Determine blast radius (single request type vs multi-flow outage).
2. Capture correlation IDs and representative failed transactions.
3. Categorize failure type (auth/config/validation/dependency/transient).
4. Apply documented remediation path for the detected category.
5. Execute replay/reprocessing only after remediation is confirmed.

## Coordination Notes
- Share exact error signatures and timestamps with Salesforce support.
- Use agreed escalation matrix when dependency owners are unknown.

## Escalate When
- Failure rate remains elevated after first remediation cycle.
- Root cause requires platform-level access or vendor support.
