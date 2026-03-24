# ISS Support Analyst Runbook

## Mission
Provide rapid triage, accurate categorization, and clean escalation packages.

## Core responsibilities
- Detect and classify incident-sync failures.
- Use transaction logs to determine impact and urgency.
- Execute safe, approved first-response actions.
- Escalate with complete technical context.

## First 10 minutes triage
1. Identify scope: single case, single org, or multi-org.
2. Capture `Status__c`, `ErrorCategory__c`, `ErrorCode__c`, `CorrelationId__c`.
3. Check `ServiceNow_Incident_Link__c` for duplicate risk.
4. Determine if issue is security/config/validation/transport/platform/unknown.

## Allowed actions
- Monitor in-flight transactions within normal SLA windows.
- Request admin validation for configuration issues.
- Trigger approved replay flow for eligible and safe records.
- Open escalation per matrix when threshold met.

## Not allowed without escalation
- Repeated manual retries during security/auth failures.
- Bulk replay when duplicate risk is unknown.
- Untracked production metadata changes.

## Escalation package template
- Impacted org(s) and request type(s)
- # failed / # retrying / # abandoned
- Top error codes with counts
- Sample transaction IDs + correlation IDs
- Start time and latest occurrence (UTC)

## Done criteria
- Correct owner engaged.
- Customer/business communication updated.
- Incident timeline reflects all actions and decisions.
